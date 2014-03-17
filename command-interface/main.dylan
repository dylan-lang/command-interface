module: command-interface
synopsis: Convenience main functions.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define function tty-command-shell-main (name :: <string>, arguments :: <vector>, tty :: <tty>, root :: <command-root>)
  let source = make(<command-vector-source>, strings: arguments);
  let parser = make(<command-parser>, source: source, initial-node: root);

  let status = 1;

  block ()
    let tokens = command-tokenize(source);

    // XXX This special case for bash completion is a hack.
    //     It ensures that completion results don't get garbled by tty handling.
    if (~empty?(tokens) & token-string(tokens[0]) = "bashcomplete")
      parser-parse(parser, tokens);
      parser-execute(parser);
    else
      with-tty (tty)
        if (empty?(tokens))
          let editor = make(<tty-command-shell>, root-node: root);
          tty-start-activity(tty, editor);
        else
          parser-parse(parser, tokens);
          parser-execute(parser);
        end;
        tty-run(tty);
      end;
    end;

    status := 0;
  exception (le :: <command-lexer-error>)
    format-err(" %s\n %s\n%s\n",
               source-string(source),
               command-annotate(source, le.error-srcoff),
               condition-to-string(le));
    force-err();
  exception (pe :: <command-parse-error>)
    format-err(" %s\n %s\n%s\n",
               source-string(source),
               command-annotate(source, token-srcloc(pe.error-token)),
               condition-to-string(pe));
    force-err();
  exception (e :: <error>)
    format-err("Error: %=\n", e);
    force-err();
  end;

  exit-application(status);
end function;
