module: command-interface
synopsis: TTY activity for the CLI.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define class <tty-command-shell> (<tty-editor>)
  slot tty-command-shell-root-node :: <command-node>,
    required-init-keyword: root-node:;
end class;

define method editor-execute (editor :: <tty-command-shell>)
 => ();
  // clean line for command
  editor-finish(editor);
  // instantiate source and parser
  let str = editor-line(editor);
  let src = make(<command-string-source>, string: str);
  let parser = make(<command-parser>, source: src,
                    initial-node: tty-command-shell-root-node(editor));
  // process the command
  block ()
    // tokenize
    let tokens = command-tokenize(src);
    // parse
    parser-parse(parser, tokens);
    // verify
    parser-verify(parser);
    // execute
    parser-execute(parser);
    // clear editor if successful
    editor-clear(editor);
  exception (le :: <command-lexer-error>)
    // print with annotations
    format-out("%s%s\n%s\n",
               n-spaces(size(editor-prompt(editor))),
               command-annotate(src, le.error-srcoff),
               condition-to-string(le));
  exception (pe :: <command-parse-error>)
    // print with annotations
    format-out("%s%s\n%s\n",
               n-spaces(size(editor-prompt(editor))),
               command-annotate(src, token-srcloc(pe.error-token)),
               condition-to-string(pe));
  exception (e :: <error>)
    // print condition and clear
    format-out("Error: %=\n", e);
    editor-clear(editor);
  end;
  // trigger a redraw
  editor-refresh-line(editor);
end method;


define method replace-token (editor :: <tty-command-shell>, token :: <command-token>, autospace? :: <boolean>, replacement :: <string>)
 => ();
  let reploc = token-srcloc(token);
  let s = source-location-start-character(reploc);
  let e = source-location-end-character(reploc) + 1;
  if (autospace?)
    editor-replace(editor, s, e, concatenate(replacement, " "));
  else
    editor-replace(editor, s, e, replacement);
  end;
end method;

define method replace-position (editor :: <tty-command-shell>, position :: <integer>, autospace? :: <boolean>, replacement :: <string>)
 => ();
  if (autospace?)
    editor-replace(editor, position, position, concatenate(replacement, " "));
  else
    editor-replace(editor, position, position, replacement);
  end;
end method;


// this should possibly be merged with the bashcomp version somehow.
define method editor-complete-internal (editor :: <tty-command-shell>)
 => (completions :: <list>, token :: false-or(<command-token>));
  // get editor state
  let str = editor-line(editor);
  let posn = editor-position(editor);
  // construct source and parser
  let src = make(<command-string-source>, string: str);
  let parser = make(<command-parser>, source: src,
                    initial-node: tty-command-shell-root-node(editor));
  let comploff = command-srcoff(posn, 0, posn);
  // tokenize the line
  let tokens = command-tokenize(src);
  // get all tokens before the completion token and
  // the completion token itself, if there is one.
  // not having a completion token means that we
  // are completing between tokens or at the end of
  // the line.
  let parse-tokens = #();
  let complete-token = #f;
  for (token in tokens, until: true?(complete-token))
    if (token-type(token) ~= #"whitespace")
      if (in-completion-location?(token-srcloc(token), comploff))
        // XXX we should cut this token off at the cursor
        //     location, probably make parser-complete()
        //     and node-complete take a string instead of a token.
        complete-token := token;
      else
        parse-tokens := add(parse-tokens, token);
      end;
    end;
  end for;
  // parse everything before the compl token
  for (token in reverse(parse-tokens))
    parser-advance(parser, token);
  end for;
  // complete, with or without a compl token
  values(parser-complete(parser, complete-token), complete-token);
end method;

define method editor-complete-implicit (editor :: <tty-command-shell>)
 => (accepted? :: <boolean>);
  // perform completion
  let (completions, complete-token) =
    block ()
      editor-complete-internal(editor);
    exception (le :: <command-lexer-error>)
      values(#(), #f);
    exception (pe :: <command-parse-error>)
      values(#(), #f);
    end;
  // get all completions as raw strings
  let options = apply(concatenate, #(),
                      map(completion-options, completions));
  let exhaustive? = every?(completion-exhaustive?, completions);
  // we only complete when there is an existing token
  if (complete-token)
    // act on the completion
    select (size(options))
      // don't do anything if we have nothing
      0 => #t;
      // replace single completions
      1 =>
        begin
          let option = first(options);
          let completion = option.option-string;
          if (exhaustive?)
            replace-token(editor, complete-token, #f, completion);
          end;
          option.option-complete? | ~exhaustive?;
        end;
      // else, insert the longest common prefix
      otherwise =>
        begin
          let option-strings = map(option-string, options);
          let common = longest-common-prefix(option-strings);
          let matching = choose-by(curry(\=, common), option-strings, options);
          let option = if (empty?(matching)) #f else first(matching) end;
          if (exhaustive?)
            replace-token(editor, complete-token, #f, common);
          end;
          (option & option.option-complete?) | ~exhaustive?;
        end;
    end;
  end;
end method;

define method editor-complete (editor :: <tty-command-shell>)
 => ();
  block (return)
    // perform completion, abort on error
    let (completions, complete-token) =
      block ()
        editor-complete-internal(editor);
      exception (le :: <command-lexer-error>)
        editor-finish(editor);
        format-out("%s%s\n%s\n",
                   n-spaces(size(editor-prompt(editor))),
                   command-annotate(le.error-source,
                                le.error-srcoff),
                   condition-to-string(le));
        return();
      exception (pe :: <command-parse-error>)
        editor-finish(editor);
        format-out("%s%s\n%s\n",
                   n-spaces(size(editor-prompt(editor))),
                   command-annotate(pe.error-parser.parser-source,
                                token-srcloc(pe.error-token)),
                   condition-to-string(pe));
        return();
      end;
    // get all completions as raw strings
    let options = apply(concatenate, #(),
                        map(completion-options, completions));
    let option-strings = map(option-string, options);
    // we need the position in case we don't have a token
    let posn = editor-position(editor);
    // act on completion results
    select (size(options))
      // no completions -> say so
      0 =>
        begin
          editor-finish(editor);
          format-out("no completions\n");
        end;
      // one completion -> insert it
      1 =>
        let option = first(options);
        let completion = option-string(option);
        let autospace? = option-complete?(option) & option-completion(option).completion-exhaustive?;
        if (complete-token)
          replace-token(editor, complete-token, autospace?, completion);
        else
          replace-position(editor, posn, autospace?, completion);
        end;
      // many completions -> insert longest common prefix and print options
      otherwise =>
        editor-finish(editor);
        let complete-options = choose(option-complete?, options);
        let complete-strings = map(option-string, complete-options);
        format-out("%s\n", join(option-strings, " ")); // XXX only complete options for exhaustive case ???
        let common = longest-common-prefix(complete-strings);

        let matching-options = choose-by(rcurry(starts-with?, common),
                                         complete-strings, complete-options);
        let matching = choose-by(curry(\=, common), option-strings, options);
        let option = if (empty?(matching)) #f else first(matching) end;
        let autospace? = (size(matching-options) = 1) & option & option.option-complete?;
        if (complete-token)
          replace-token(editor, complete-token, autospace?, common);
        else
          replace-position(editor, posn, autospace?, common);
        end;
    end select;
  end block;
  editor-refresh-line(editor);
end method;
