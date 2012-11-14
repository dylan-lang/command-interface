module: cli


define constant $cli-root = make(<cli-root>);

root-define-command($cli-root, "help",
                    node-class: <cli-wrapper>,
                    wrapped: $cli-root,
                    handler:
                      method(parser :: <cli-parser>)
                       => ();
                          let nodes = reverse(parser-nodes(parser));
                          let tokens = reverse(parser-tokens(parser));
                          // skip "help"
                          nodes := tail(nodes);
                          tokens := tail(tokens);

                          let cmd :: false-or(<cli-command>) = #f;
                          let cmd-title :: <list> = #();
                          let cmd-help :: false-or(<string>) = #f;

                          for(token in tokens, node in nodes)
                            if(instance?(node, <cli-symbol>))
                              if(~cmd)
                                cmd-title := add(cmd-title, node-symbol(node));
                              end if;
                            end if;
                            if(instance?(node, <cli-command>))
                              cmd := node;
                              if(command-help(node))
                                cmd-help := command-help(node);
                              end if;
                            end if;
                          end for;

                          format-out("command %=\n", cmd-title);
                          format-out("help:\n%s\n", cmd-help);
                      end method);


define constant $bashcomp =
  root-define-command
  ($cli-root, "bashcomplete",
   hidden?: #t,
   handler:
     method(parser :: <cli-parser>)
      => ();
         // get arguments passed by bash
         let command = parser-get-parameter(parser, #"command");
         if(~command)
           let appname = application-name();
           format-out("function _%s_complete() {\n", appname);
           format-out("  COMPREPLY=($(%s bashcomplete ${COMP_CWORD} ${COMP_WORDS[@]}))\n", appname);
           format-out("}\n");
           format-out("complete -F _%s_complete %s\n", appname, appname);
         else
           command := reverse(command);
           // parse position
           let position = string-to-integer(element(command, 0), default: 9999);
           // skip position
           command := tail(command);
           // skip argv[0]
           command := tail(command);
           position := position - 1;
           // create a parser
           let src = make(<cli-vector-source>,
                          strings: command);
           let p = make(<cli-parser>,
                        source: src,
                      initial-node: $cli-root);
           // tokenize the command
           let tokens = cli-tokenize(src);
           // perform completion
           let completions = #f;
           for(t in tokens, i from 0, while: i <= position)
             if(i == position)
               // complete with given token
               completions := parser-complete(p, t);
             else
             // advance the parser
               block ()
                 parser-advance(p, t);
               exception (<error>)
                 "XXX";
               end block;
             end
           end for;
           // we are completing without a token
           if(~completions)
             completions := parser-complete(p, #f);
           end if;
           // print completion
           for(completion in completions)
             format-out("%s\n", completion);
           end for;
         end if;
     end method);

make-simple-param($bashcomp, #"command", repeatable?: #t);


define variable $show-if = root-define-command($cli-root, #["show", "interface"],
                                               help: "Query the interface database");
make-named-param($show-if, #"name", repeatable?: #t);
make-named-param($show-if, #"type");

define variable $show-rt = root-define-command($cli-root, #["show", "route"],
                                               help: "Query the route database");
make-simple-param($show-rt, #"spec");

root-define-command($cli-root, #["show", "log"],
                    help: "Show system log");
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
    cli-annotate(*standard-error*,
                 parser-source(pe.error-parser),
                 token-srcloc(pe.error-token));
    force-output(*standard-error*);
  end;

  exit-application(0);
end function main;

main(application-name(), application-arguments());
