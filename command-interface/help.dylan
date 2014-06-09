module: command-interface
synopsis: Reusable help command.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define method root-add-help (root :: <command-root>)
 => ();
  build-command(root, "help",
                node-class: <command-wrapper>,
                root: root,
                handler: help-handler);
end method;

define method help-handler (parser :: <command-parser>)
 => ();
  let nodes = reverse(parser-nodes(parser));
  let tokens = reverse(parser-tokens(parser));

  // skip "help"
  nodes := tail(nodes);
  tokens := tail(tokens);

  // print help
  show-command-help(nodes, tokens);
end method;

define method show-command-help (nodes :: <sequence>, tokens :: <sequence>)
  => ();
  let cmd :: false-or(<command-command>) = #f;
  let cmd-title :: <list> = #();
  let cmd-help :: false-or(<string>) = #f;

  for (token in tokens, node in nodes)
    if (instance?(node, <command-symbol>))
      if (~cmd)
        cmd-title := add(cmd-title, as(<string>, node-symbol(node)));
      end if;
    end if;
    if (instance?(node, <command-command>))
      cmd := node;
      if (command-help(node))
        cmd-help := command-help(node);
      end if;
    end if;
  end for;

  if (~cmd)
    error("Incomplete command.");
  end;

  cmd-title := reverse(cmd-title);
  cmd-title := map(as-lowercase, cmd-title);

  if (~cmd-help)
    cmd-help := "No help.";
  end;

  format-out("\n");
  format-out("  %s\n    %s\n\n", join(cmd-title, " "), cmd-help);

  for (parameter in command-parameters(cmd))
    let param-help = parameter-help(parameter);
    if (~param-help)
      param-help := "No help.";
    end;
    select (parameter-kind(parameter))
      #"flag" =>
        begin
          format-out("    %s\n", parameter-name(parameter));
          format-out("     %s\n", param-help);
        end;
      #"simple" =>
        begin
          format-out("    <%s>\n", parameter-name(parameter));
          format-out("      %s\n", param-help);
        end;
      #"named" =>
        begin
          format-out("    %s <value>\n", parameter-name(parameter));
          format-out("      %s\n", param-help);
        end;
    end;
  end;
end method;
