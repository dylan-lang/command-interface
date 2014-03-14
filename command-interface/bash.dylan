module: command-interface
synopsis: Reusable bash completion.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

/* Add hidden command for bash completion to given root
 */
define method root-add-bash-completion (root :: <command-root>)
 => ();
  let command = root-define-command
    (root, "bashcomplete",
     hidden?: #t,
     handler: bash-complete-handler);
  make-simple-param(command, #"command", repeatable?: #t);
end method;

/* Handler for the "bashcomplete" command
 */
define method bash-complete-handler (parser :: <command-parser>)
 => ();
  // get arguments passed by bash
  let command = parser-get-parameter(parser, #"command");
  if (command)
    bash-complete-command(parser, reverse(command));
  else
    bash-complete-hookscript();
  end if;
end method;

/* Generate and print a hookscript suitable for
 * integrating the current binary into bash completion
 */
define method bash-complete-hookscript ()
 => ();
  let appname = application-name();
  format-out("function _%s_complete() {\n", appname);
  format-out("  COMPREPLY=($(%s bashcomplete ${COMP_CWORD} ${COMP_WORDS[@]}))\n", appname);
  format-out("}\n");
  format-out("complete -F _%s_complete %s\n", appname, appname);
end method;

/* Handler for actual bash completion
 *
 * This should not print anything except for simple completion result tokens.
 */
define method bash-complete-command (parser :: <command-parser>, command)
 => ();
  // parse position
  let position = string-to-integer(element(command, 0), default: 9999);
  // skip position
  command := tail(command);
  // skip argv[0]
  command := tail(command);
  position := position - 1;
  block ()
    // create a parser
    let src = make(<command-vector-source>,
                   strings: command);
    let p = make(<command-parser>,
                 source: src,
                 initial-node: parser-initial-node(parser));
    // tokenize the command
    let tokens = command-tokenize(src);
    // perform completion
    let completions = #f;
    for (t in tokens, i from 0, while: i <= position)
      if (token-type(t) ~= #"whitespace")
        if (i == position)
          // complete with given token
          completions := parser-complete(p, t);
        else
          // advance the parser
          parser-advance(p, t);
        end;
      end;
    end for;
    // we are completing without a token
    if (~completions)
      completions := parser-complete(p, #f);
    end if;
    // print completion
    let all-completion-results =
      apply(concatenate, #(), map(completion-results, completions));
    for (completion in all-completion-results)
      format-out("%s\n", completion);
    end for;
  exception (e :: <error>)
    format(*standard-error*, "Error: %=\n", e);
    force-output(*standard-error*);
  end block;
end method;
