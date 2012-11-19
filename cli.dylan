module: cli


define constant $cli-root = make(<cli-root>);

root-add-bash-completion($cli-root);
root-add-help($cli-root);


define variable $show-if = root-define-command($cli-root, #["show", "interface"],
                                               help: "Query the interface database");

// property params
make-inline-param($show-if, #"name");
make-named-param($show-if, #"type");


root-define-command($cli-root, #"shell",
                    handler:
                      method(p :: <cli-parser>)
                          let t = application-controlling-tty();
                          let e = make(<tty-cli>);
                          tty-run(t, e);
                      end method);

define variable $show-rt = root-define-command($cli-root, #["show", "route"],
                                               help: "Query the route database");

// lookup params
make-inline-param($show-rt, #"to");
make-named-param($show-rt,  #"from");

// property params
make-named-param($show-rt,  #"device");
make-named-param($show-rt,  #"source");
make-named-param($show-rt,  #"nexthop");


let sl = root-define-command($cli-root, #["show", "log"],
                    help: "Show system log");
let fp = make(<cli-file>, name: #"file");
node-add-successor(sl, fp);

root-define-command($cli-root, #["show", "configuration"],
                    help: "Show active system configuration");



define function main (name :: <string>, arguments :: <vector>)
  let source = make(<cli-vector-source>, strings: arguments);
  let parser = make(<cli-parser>, source: source, initial-node: $cli-root);

  let tokens = cli-tokenize(source);

  block ()
    parser-parse(parser, tokens);
    parser-execute(parser);
  exception (pe :: <cli-parse-error>)
    apply(format, *standard-error*,
          condition-format-string(pe),
          condition-format-arguments(pe));
    cli-annotate(source,
                 token-srcloc(pe.error-token));
    force-output(*standard-error*);
  end;

  exit-application(0);
end function main;

main(application-name(), application-arguments());
