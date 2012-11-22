module: cli

define method root-add-bash-completion (root :: <cli-root>)
 => ();
  let command = root-define-command
    (root, "bashcomplete",
     hidden?: #t,
     handler: bash-complete-handler);
  make-simple-param(command, #"command", repeatable?: #t);
end method;

define method bash-complete-handler (parser :: <cli-parser>)
 => ();
  // get arguments passed by bash
  let command = parser-get-parameter(parser, #"command");
  if (command)
    bash-complete-command(parser, reverse(command));
  else
    bash-complete-hookscript();
  end if;
end method;

define method bash-complete-hookscript ()
 => ();
  let appname = application-name();
  format-out("function _%s_complete() {\n", appname);
  format-out("  COMPREPLY=($(%s bashcomplete ${COMP_CWORD} ${COMP_WORDS[@]}))\n", appname);
  format-out("}\n");
  format-out("complete -F _%s_complete %s\n", appname, appname);
end method;

define method bash-complete-command (parser :: <cli-parser>, command)
 => ();
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
  for (t in tokens, i from 0, while: i <= position)
    if (i == position)
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
  if (~completions)
    completions := parser-complete(p, #f);
  end if;
  // print completion
  for (completion in completions)
    format-out("%s\n", completion);
  end for;
end method;
