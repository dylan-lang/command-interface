module: command-system-demo
synopsis: Demo code.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define command-root $root;

define command quit ($root)
  help "Quit the shell";
  implementation
      tty-finish-activity(current-tty());
end;

define command fail ($root)
  help "Fail miserably";
  implementation
      error("Demo error");
end;

define command directory ($root)
  help "Show information about directory";
  simple parameter directory :: <string>,
    node-class: <command-file>,
    accept-file?: #f,
    must-exist?: #t;
  implementation
    format-out("Nothing to show...\n");
end;

define command show configuration ($root)
  help "Query configuration";
  implementation
    format-out("Nothing to show...\n");
end;

define command show interface ($root)
  help "Query interfaces";
  simple parameter name :: <string>,
    node-class: <command-oneof>,
    alternatives: #("eth0", "eth1", "eth2", "eth3");
  named parameter type :: <string>,
    node-class: <command-oneof>,
    alternatives: #("ethernet","atm");
  named parameter protocol :: <string>,
    node-class: <command-oneof>,
    alternatives: #("ip","ip4","ip6","lldp");
  implementation
    format-out("Nothing to show...\n");
end;

define command show route ($root)
  help "Query routes";
  named parameter destination :: <symbol>;
  named parameter source :: <symbol>;
  implementation
    format-out("Nothing to show...\n src %= dst %= \n", source, destination);
end;

define command show log ($root)
  help "Query logs";
  named parameter service :: <string>,
    node-class: <command-oneof>,
    alternatives: #("dhcp-server","dhcp-client","kernel");
  named parameter level :: <string>,
    node-class: <command-oneof>,
    alternatives: #("fatal","error","warning","notice","info","debug","trace");
  implementation
    format-out("Nothing to show...\n");
end;

define command configure ($root)
  help "Modify configuration";
  implementation
    tty-start-activity(current-tty(),
                       make(<tty-command-shell>,
                            root-node: $configure,
                            prompt: "config$ "));
end;

define command-root $configure;

define command diff ($configure)
  help "Show changes";
  implementation
    format-out("Configuration unchanged.\n");
end;

define command set ($configure)
  help "Change a parameter";
  implementation
    format-out("Not implemented...\n");
end;

define command show ($configure)
  help "Show configuration";
  implementation
    format-out("Nothing to show...\n");
end;

define command remark ($configure)
  help "Add remark on current config transaction";
  implementation
    format-out("Not implemented...\n");
  simple parameter remark;
end;

define command abort ($configure)
  help "Abort current config transaction";
  implementation
    begin
      format-out("Aborting configuration change.\n");
      tty-finish-activity(current-tty());
    end;
end;

define command commit ($configure)
  help "Commit current config transaction";
  implementation
    begin
      format-out("Not really doing anything but we might...\n");
      tty-finish-activity(current-tty());
    end;
end;

tty-command-shell-main(application-name(), application-arguments(),
                       application-controlling-tty(),
                       $root);
