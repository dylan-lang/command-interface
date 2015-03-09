module: command-interface-demo
synopsis: Demo code.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define command-root $root;

define command quit ($root)
  help "Quit the shell";
  implementation
      tty-finish-activity(current-tty());
end;

define command error ($root)
  help "Fail miserably";
  simple parameter message :: <string>,
    required: #t;
  implementation
      error(message);
end;

define command examine ($root)
  simple parameter object :: <string>,
    required?: #t,
    repeatable?: #t;
  implementation
    begin
      format-out("Doing almost nothing...\nOBJECTS: %=\n", object);
    end;
end;

define command directory ($root)
  help "Show information about directory";
  simple parameter directory :: <string>,
    node-class: <file-node>,
    accept-file?: #f,
    must-exist?: #t;
  implementation
    format-out("Nothing to show...\n");
end;

define command echo ($root)
  simple parameter message :: <string>,
    help: "Message to print",
    required: #t;
  implementation
      format-out("%s\n", message);
end;

define command show ($root)
  help "Show information";
end;

define command show configuration ($root)
  help "Query configuration";
  implementation
    format-out("Nothing to show...\n");
end;

define command show interface ($root)
  help "Query interfaces";
  flag parameter verbose :: <boolean>;
  simple parameter name :: <string>,
    help: "Name of the interface",
    node-class: <oneof-node>,
    alternatives: #("eth0", "eth1", "eth2", "eth3");
  named parameter type :: <string>,
    help: "Filter interfaces by type",
    node-class: <oneof-node>,
    alternatives: #("ethernet","atm");
  named parameter protocol :: <string>,
    help: "Filter interfaces by protocol",
    node-class: <oneof-node>,
    alternatives: #("ip","ip4","ip6","lldp");
  implementation
    format-out("Nothing to show... %= | %=\n", verbose, name);
end;

define command show route ($root)
  help "Query routes";
  named parameter destination :: <symbol>,
    help: "Filter routes by destination";
  named parameter source :: <symbol>,
    help: "Filter routes by source";
  implementation
    format-out("Nothing to show...\n src %= dst %= \n", source, destination);
end;

define command show log ($root)
  help "Query logs";
  named parameter service :: <string>,
    help: "Filter log messages by service",
    node-class: <oneof-node>,
    alternatives: #("dhcp-server","dhcp-client","kernel");
  named parameter level :: <string>,
    help: "Filter log messages by level",
    node-class: <oneof-node>,
    alternatives: #("fatal","error","warning","notice","info","debug","trace");
  implementation
    format-out("Nothing to show...\n");
end;

define command show rule ($root)
  help "Query rules";
  named parameter src-interface :: <string>;
  named parameter src-address :: <string>;
  named parameter dst-interface :: <string>;
  named parameter dst-address :: <string>;
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
