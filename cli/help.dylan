module: cli
synopsis: Reusable help command.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file COPYING

define method root-add-help (root :: <cli-root>)
 => ();
  root-define-command(root, "help",
                      node-class: <cli-wrapper>,
                      root: root,
                      handler: help-handler);
end method;

define method help-handler (parser :: <cli-parser>)
 => ();
  let nodes = reverse(parser-nodes(parser));
  let tokens = reverse(parser-tokens(parser));

  // skip "help"
  nodes := tail(nodes);
  tokens := tail(tokens);

  let cmd :: false-or(<cli-command>) = #f;
  let cmd-title :: <list> = #();
  let cmd-help :: false-or(<string>) = #f;

  for (token in tokens, node in nodes)
    if (instance?(node, <cli-symbol>))
      if (~cmd)
        cmd-title := add(cmd-title, as(<string>, node-symbol(node)));
      end if;
    end if;
    if (instance?(node, <cli-command>))
      cmd := node;
      if (command-help(node))
        cmd-help := command-help(node);
      end if;
    end if;
  end for;

  cmd-title := reverse(cmd-title);
  cmd-title := map(as-uppercase, cmd-title);

  format-out("\n    %s\n\n", join(cmd-title, " "));
  format-out("    %s\n\n", cmd-help);
end method;
