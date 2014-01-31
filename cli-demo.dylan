module: cli-demo
synopsis: Demo code.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file COPYING

define cli-root $root;

define cli-command $root (directory)
  help "Show information about directory";
  implementation
    format-out("Nothing to show...\n");
  simple parameter directory :: <cli-file>,
    accept-file?: #f,
    must-exist?: #t;
end;

define cli-command $root (show configuration)
  help "Query configuration";
  implementation
    format-out("Nothing to show...\n");
end;

define cli-command $root (show interface)
  help "Query interfaces";
  named parameter type;
  implementation
    format-out("Nothing to show...\n");
end;

define cli-command $root (show route)
  help "Query routes";
  named parameter destination;
  named parameter source;
  implementation
    format-out("Nothing to show...\n");
end;

define cli-command $root (show log)
  help "Query logs";
  named parameter service :: <cli-oneof>,
    alternatives: #("dhcp-server","dhcp-client","kernel");
  named parameter level :: <cli-oneof>,
    alternatives: #("fatal","error","warning","notice","info","debug","trace");
  implementation
    format-out("Nothing to show...\n");
end;

define cli-command $root (configure)
  help "Modify configuration";
  implementation
    tty-start-activity(current-tty(),
                       make(<tty-cli>,
                            root-node: $configure,
                            prompt: "config$ "));
end;

define cli-root $configure;

define cli-command $configure (diff)
  help "Show changes";
end;

define cli-command $configure (set)
  help "Change a parameter";
end;

define cli-command $configure (show)
  help "Show configuration";
end;

define cli-command $configure (abort)
  implementation
    tty-finish-activity(current-tty());
end;

define cli-command $configure (commit)
  implementation
    tty-finish-activity(current-tty());
end;


tty-cli-main(application-name(), application-arguments(),
             application-controlling-tty(),
             $root);
