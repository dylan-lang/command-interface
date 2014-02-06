module: cli-demo
synopsis: Demo code.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file COPYING

define cli-root $root;

define cli-command $root (quit)
  help "Quit the shell";
  implementation
      tty-finish-activity(current-tty());
end;

define cli-command $root (directory)
  help "Show information about directory";
  simple parameter directory :: <cli-file>,
    accept-file?: #f,
    must-exist?: #t;
  implementation
    format-out("Nothing to show...\n");
end;

define cli-command $root (show configuration)
  help "Query configuration";
  implementation
    format-out("Nothing to show...\n");
end;

define cli-command $root (show interface)
  help "Query interfaces";
  simple parameter name :: <cli-oneof>,
    alternatives: #("eth0", "eth1", "eth2", "eth3");
  named parameter type :: <cli-oneof>,
    alternatives: #("ethernet","atm");
  named parameter protocol :: <cli-oneof>,
    alternatives: #("ip","ip4","ip6","lldp");
  implementation
    format-out("Nothing to show...\n");
end;

define cli-command $root (show route)
  help "Query routes";
  named parameter destination;
  named parameter source;
  implementation
    format-out("Nothing to show...\n src %= dst %= \n", source, destination);
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
  implementation
    format-out("Configuration unchanged.\n");
end;

define cli-command $configure (set)
  help "Change a parameter";
  implementation
    format-out("Not implemented...\n");
end;

define cli-command $configure (show)
  help "Show configuration";
  implementation
    format-out("Nothing to show...\n");
end;

define cli-command $configure (remark)
  help "Add remark on current config transaction";
  implementation
    format-out("Not implemented...\n");
  simple parameter remark;
end;

define cli-command $configure (abort)
  help "Abort current config transaction";
  implementation
    begin
      format-out("Aborting configuration change.\n");
      tty-finish-activity(current-tty());
    end;
end;

define cli-command $configure (commit)
  help "Commit current config transaction";
  implementation
    begin
      format-out("Not really doing anything but we might...\n");
      tty-finish-activity(current-tty());
    end;
end;

tty-cli-main(application-name(), application-arguments(),
             application-controlling-tty(),
             $root);
