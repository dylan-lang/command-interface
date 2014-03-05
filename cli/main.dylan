module: cli
synopsis: Convenience main functions.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define function tty-cli-main (name :: <string>, arguments :: <vector>, tty :: <tty>, root :: <cli-root>)
  let source = make(<cli-vector-source>, strings: arguments);
  let parser = make(<cli-parser>, source: source, initial-node: root);

  let tokens = cli-tokenize(source);

  if (empty?(tokens))
    let e = make(<tty-cli>, root-node: root);
    tty-run(tty, e);
  else
      block ()
        parser-parse(parser, tokens);
        parser-execute(parser);
      exception (pe :: <cli-parse-error>)
        format(*standard-error*,
               " %s\n %s\n%s\n",
               source-string(source),
               cli-annotate(source,
                            token-srcloc(pe.error-token)),
               condition-to-string(pe));
        force-output(*standard-error*);
      end;
  end;

  exit-application(0);
end function;
