module: cli

define class <tty-event> (<object>)
  slot event-tty :: <tty>,
    required-init-keyword: tty:;
end class;


define class <tty-interrupt> (<tty-event>, <condition>)
end class;

define method default-handler(ti :: <tty-interrupt>)
 => ();
  format(*standard-error*, "Program interrupted.\n");
  exit-application(1);
end method;


define class <tty-suspend> (<tty-event>, <condition>)
end class;


define class <tty-key> (<tty-event>)
  slot key-control? :: <boolean> = #f,
    init-keyword: control?:;
  slot key-character :: false-or(<byte-character>) = #f,
    init-keyword: character:;
  slot key-function :: false-or(<symbol>) = #f,
    init-keyword: function:;
end class;

define method key-character?(k :: <tty-key>)
 => (ischar? :: <boolean>);
  true?(k.key-character);
end method;
