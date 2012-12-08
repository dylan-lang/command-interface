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
  // clean line for command
  editor-finish(editor);
  // instantiate source and parser
  let str = editor-line(editor);
  let src = make(<cli-string-source>, string: str);
  let parser = make(<cli-parser>, source: src,
                    initial-node: tty-cli-root-node(editor));
  // process the command
  block ()
    // tokenize
    let tokens = cli-tokenize(src);
    // parse
    parser-parse(parser, tokens);
    // execute
    parser-execute(parser);
    // clear editor if successful
    editor-clear(editor);
  exception (le :: <cli-lexer-error>)
    // print with annotations
    format(*standard-error*, "%s%s\n%s\n",
           n-spaces(size(editor-prompt(editor))),
           cli-annotate(src, le.error-srcoff),
           condition-to-string(le));
  exception (pe :: <cli-parse-error>)
    // print with annotations
    format(*standard-error*, "%s%s\n%s\n",
           n-spaces(size(editor-prompt(editor))),
           cli-annotate(src, token-srcloc(pe.error-token)),
           condition-to-string(pe));
  end;
  // trigger a redraw
  editor-refresh-line(editor);
end method;

define method replace (editor :: <tty-cli>,
                start-posn :: <integer>,
                end-posn :: <integer>,
                autospace? :: <boolean>,
                replacement :: <string>)
 => ();
  let str = editor-line(editor);
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
  editor-refresh-line(editor);
end method;

define method replace-token (editor :: <tty-cli>, token :: <cli-token>, autospace? :: <boolean>, replacement :: <string>)
 => ();
  let reploc = token-srcloc(token);
  replace(editor,
          source-location-start-character(reploc),
          source-location-end-character(reploc) + 1,
          autospace?,
          replacement);
end method;

define method replace-position (editor :: <tty-cli>, position :: <integer>, autospace? :: <boolean>, replacement :: <string>)
 => ();
  replace(editor, position, position, autospace?, replacement);
end method;


// this should possibly be merged with the bashcomp version somehow.
define method editor-complete-internal (editor :: <tty-cli>)
 => (completions :: <sequence>, complete-token :: false-or(<cli-token>));
  // get editor state
  let str = editor-line(editor);
  let posn = editor-position(editor);
  // construct source and parser
  let src = make(<cli-string-source>, string: str);
  let parser = make(<cli-parser>, source: src,
                    initial-node: tty-cli-root-node(editor));
  let comploff = cli-srcoff(posn, 0, posn);
  // tokenize the line
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
  values(parser-complete(parser, complete-token), complete-token);
end method;

define method editor-complete-implicit (editor :: <tty-cli>)
 => (accepted? :: <boolean>);
  // perform completion
  let (completions, complete-token) =
    block ()
      editor-complete-internal(editor);
    exception (le :: <cli-lexer-error>)
      values(#(), #f);
    exception (pe :: <cli-parse-error>)
      values(#(), #f);
    end;
  // we only complete when there is an existing token
  if (complete-token)
    // act on the completion
    select (size(completions))
      // don't do anything if we have nothing
      0 => #f;
      // replace single completions
      1 =>
        begin
          let completion = first(completions);
          replace-token(editor, complete-token, #f, completion);
          #t;
        end;
      // else, insert the longest common prefix
      otherwise => 
        begin
          let common = longest-common-prefix(completions);
          replace-token(editor, complete-token, #f, common);
          #f;
        end;
    end;
  end;
end method;

define method editor-complete (editor :: <tty-cli>)
 => ();
  // we print stuff, so clear the line
  editor-finish(editor);
  // perform completion, abort on error
  let (completions, complete-token) =
    block ()
      editor-complete-internal(editor);
    exception (le :: <cli-lexer-error>)
      format(*standard-error*, "\n%s%s\n%s\n",
             n-spaces(size(editor-prompt(editor))),
             cli-annotate(le.error-source,
                          le.error-srcoff),
             condition-to-string(le));
      editor-refresh-line(editor);
      values(#(), #f);
    exception (pe :: <cli-parse-error>)
      format(*standard-error*, "\n%s%s\n%s\n",
             n-spaces(size(editor-prompt(editor))),
             cli-annotate(pe.error-parser.parser-source,
                          token-srcloc(pe.error-token)),
             condition-to-string(pe));
      editor-refresh-line(editor);
      values(#(), #f);
    end;
  // we need the position in case we don't have a token
  let posn = editor-position(editor);
  // act on completion results
  select (size(completions))
    // no completions -> say so
    0 =>
      begin
        format-out("No completions.\n");
        editor-refresh-line(editor);
      end;
    // one completion -> insert it
    1 =>
      let completion = first(completions);
      if (complete-token)
        replace-token(editor, complete-token, #t, completion);
      else
        replace-position(editor, posn, #t, completion);
      end;
    // many completions -> insert longest common prefix
    otherwise =>
      format-out("%s\n", join(completions, " "));
      let common = longest-common-prefix(completions);
      if (complete-token)
        replace-token(editor, complete-token, #f, common);
      else
        replace-position(editor, posn, #f, common);
      end;
  end select;
end method;
