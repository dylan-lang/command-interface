module: command-interface
synopsis: Reusable help command.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define method root-add-help (root :: <root-node>)
 => ();
  build-command(root, "help",
                node-class: <wrapper-node>,
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
  let cmd :: false-or(<command-node>) = #f;
  let cmd-title :: <list> = #();
  let cmd-help :: false-or(<string>) = #f;

  // find the last command node
  for (token in tokens, node in nodes)
    if (instance?(node, <command-node>))
      cmd := node;
      cmd-title := add(cmd-title, as(<string>, node-symbol(node)));
      if (command-help(node))
        cmd-help := command-help(node);
      end if;
    end if;
  end for;

  // complain if no command found
  if (~cmd)
    error("Incomplete command.");
  end;

  // fudge the title
  cmd-title := reverse(cmd-title);
  cmd-title := map(as-lowercase, cmd-title);

  // default help
  if (~cmd-help)
    cmd-help := "No help.";
  end;

  // determine possible successor nodes
  let successors = node-successors(cmd);
  let commands = choose(rcurry(instance?, <command-node>), successors);
  local method is-param?(node :: <parse-node>)
          => (param? :: <boolean>);
          instance?(node, <parameter-node>) | instance?(node, <parameter-symbol-node>)
        end;
  let params = choose(is-param?, successors);

  // print stuff
  format-out("\n");
  format-out("  %s\n    %s\n", join(cmd-title, " "), cmd-help);
  format-out("\n");
  unless (empty?(commands))
    format-out("  Subcommands:\n");
    for (command in commands)
      format-out("    %s\n", node-help-symbol(command));
      format-out("      %s\n", node-help-text(command));
    end;
    format-out("\n");
  end;
  unless (empty?(params))
    format-out("  Parameters:\n");
    for (param in params)
      format-out("    %s\n", node-help-symbol(param));
      format-out("      %s\n", node-help-text(param));
    end;
    format-out("\n");
  end;
end method;
