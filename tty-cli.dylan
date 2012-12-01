module: cli
synopsis: TTY activity for the CLI.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file COPYING

define class <tty-cli> (<tty-editor>)
  slot tty-cli-root-node :: <cli-node>,
    required-init-keyword: root-node:;
end class;

define method editor-execute (editor :: <tty-cli>)
 => ();
  editor-finish(editor);

  let str = editor-line(editor);
  let src = make(<cli-string-source>, string: str);
  let parser = make(<cli-parser>, source: src,
                    initial-node: tty-cli-root-node(editor));

  block ()
    let tokens = cli-tokenize(src);
    parser-parse(parser, tokens);
    parser-execute(parser);
    editor-clear(editor);
  exception (le :: <cli-lexer-error>)
    format(*standard-error*, "%s%s\n%s\n",
           n-spaces(size(editor-prompt(editor))),
           cli-annotate(src, le.error-srcoff),
           condition-to-string(le));
  exception (pe :: <cli-parse-error>)
    format(*standard-error*, "%s%s\n%s\n",
           n-spaces(size(editor-prompt(editor))),
           cli-annotate(src, token-srcloc(pe.error-token)),
           condition-to-string(pe));
  end;

  force-output(*standard-output*);
  force-output(*standard-error*);

  editor-refresh-line(editor);
end method;

// there should be a "silent" version of this for use in "space" completion.
// it should possibly be merged with the bashcomp version somehow.
define method editor-complete (editor :: <tty-cli>)
 => ();
  editor-finish(editor);

  let str = editor-line(editor);
  let posn = editor-position(editor);
  let src = make(<cli-string-source>, string: str);
  let parser = make(<cli-parser>, source: src,
                    initial-node: tty-cli-root-node(editor));
  let comploff = cli-srcoff(posn, 0, posn);

  local
    // this should be a <tty-editor> operation,
    // without the autospace? feature
    method replace (start-posn :: <integer>,
                    end-posn :: <integer>,
                    autospace? :: <boolean>,
                    replacement :: <string>)
     => ();
      // insert automatic space
      if (autospace?)
        if (end-posn == size(str) | str[end-posn] ~= " ")
          replacement := concatenate!(replacement, " ");
        end;
      end;
      // compute new string and position
      let new-str = replace-subsequence!
        (str, replacement, start:  start-posn, end: end-posn);
      let new-posn = start-posn + size(replacement);
      // apply things to editor
      editor-line(editor) := new-str;
      editor-position(editor) := new-posn;
    end method,
    method replace-token (token :: <cli-token>, autospace? :: <boolean>, replacement :: <string>)
     => ();
      let reploc = token-srcloc(token);
      replace(source-location-start-character(reploc),
              source-location-end-character(reploc) + 1,
              autospace?,
              replacement);
    end method,
    method replace-position (position :: <integer>, autospace? :: <boolean>, replacement :: <string>)
      => ();
      replace(position, position, autospace?, replacement);
    end method;

  block ()
    let tokens = cli-tokenize(src);
    // get all tokens before the completion token and
    // the completion token itself, if there is one.
    // not having a completion token means that we
    // are completing between tokens or at the end of
    // the line.
    let parse-tokens = #();
    let complete-token = #f;
    for (token in tokens, until: true?(complete-token))
      if (in-completion-location?(token-srcloc(token), comploff))
        // XXX we should cut this token off at the cursor
        //     location, probably make parser-complete()
        //     and node-complete take a string instead of a token.
        complete-token := token;
      else
        parse-tokens := add(parse-tokens, token);
      end;
    end for;
    // parse everything before the compl token
    for (token in reverse(parse-tokens))
      parser-advance(parser, token);
    end for;
    // complete, with or without a compl token
    let completions = parser-complete(parser, complete-token);
    // act on completion results
    select (size(completions))
      // no completions -> say so
      0 =>
        format-out("No completions.\n");
      // one completion -> insert it
      1 =>
        let completion = first(completions);
        if (complete-token)
          replace-token(complete-token, #t, completion);
        else
          replace-position(posn, #t, completion);
        end;
      // many completions -> insert longest common prefix
      otherwise =>
        format-out("%s\n", join(completions, " "));
        let common = longest-common-prefix(completions);
        if (complete-token)
          replace-token(complete-token, #f, common);
        else
          replace-position(posn, #f, common);
        end;
    end select;
  exception (le :: <cli-lexer-error>)
    format(*standard-error*, "\n%s%s\n%s\n",
           n-spaces(size(editor-prompt(editor))),
           cli-annotate(src, le.error-srcoff),
           condition-to-string(le));
  exception (pe :: <cli-parse-error>)
    format(*standard-error*, "\n%s%s\n%s\n",
           n-spaces(size(editor-prompt(editor))),
           cli-annotate(src, token-srcloc(pe.error-token)),
           condition-to-string(pe));
  end;

  editor-refresh-line(editor);

  force-output(*standard-output*);
  force-output(*standard-error*);
end method;
