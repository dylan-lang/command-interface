module: cli
synopsis: Convenience main functions.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define function tty-cli-main (name :: <string>, arguments :: <vector>, tty :: <tty>, root :: <cli-root>)
  let source = make(<cli-vector-source>, strings: arguments);
  let parser = make(<cli-parser>, source: source, initial-node: root);

  let status = 1;

  block ()
    let tokens = cli-tokenize(source);

    // XXX This special case for bash completion is a hack.
    //     It ensures that completion results don't get garbled by tty handling.
    if (~empty?(tokens) & token-string(tokens[0]) = "bashcomplete")
      parser-parse(parser, tokens);
      parser-execute(parser);
    else
      with-tty (tty)
        if (empty?(tokens))
          let editor = make(<tty-cli>, root-node: root);
          tty-start-activity(tty, editor);
        else
          parser-parse(parser, tokens);
          parser-execute(parser);
        end;
        tty-run(tty);
      end;
    end;

    status := 0;
  exception (le :: <cli-lexer-error>)
    format(*standard-error*,
           " %s\n %s\n%s\n",
           source-string(source),
           cli-annotate(source, le.error-srcoff),
           condition-to-string(le));
    force-output(*standard-error*);
  exception (pe :: <cli-parse-error>)
    format(*standard-error*,
           " %s\n %s\n%s\n",
           source-string(source),
           cli-annotate(source, token-srcloc(pe.error-token)),
           condition-to-string(pe));
    force-output(*standard-error*);
  exception (e :: <error>)
    format(*standard-error*,
           "Error: %=", e);
    force-output(*standard-error*);
  end;

  exit-application(status);
end function;
