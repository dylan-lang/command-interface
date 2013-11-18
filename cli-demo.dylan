module: cli-demo
synopsis: Demo code.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file COPYING

define cli-root $root;

define cli-command $root (show configuration)
  help "Query configuration";
end;

define cli-command $root (show interface)
  help "Query interfaces";
  named parameter type;
end;

define cli-command $root (show route)
  help "Query routes";
  named parameter destination;
  named parameter source;
end;

define cli-command $root (show log)
  help "Query logs";
  named parameter service;
  named parameter level;
end;

define cli-command $root (configure)
  help "Modify configuration";
  handler method (p :: <cli-parser>)
            tty-start-activity(current-tty(),
                               make(<tty-cli>,
                                    root-node: $configure,
                                    prompt: "config$ "));
          end;
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
  handler method (p :: <cli-parser>)
            tty-finish-activity(current-tty());
          end;
end;

define cli-command $configure (commit)
  handler method (p :: <cli-parser>)
            tty-finish-activity(current-tty());
          end;
end;

tty-cli-main(application-name(), application-arguments(),
             application-controlling-tty(),
             $root);
