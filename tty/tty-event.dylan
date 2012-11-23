module: tty
synopsis: TTY event classes.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file COPYING


/* Base class of all TTY events
 */
define class <tty-event> (<object>)
  slot event-tty :: <tty>,
    required-init-keyword: tty:;
end class;


/* Events for interrupts (CTRL-C)
 */
define class <tty-interrupt> (<tty-event>, <condition>)
end class;

define method default-handler (ti :: <tty-interrupt>)
 => ();
  format(*standard-error*, "Program interrupted.\n");
  exit-application(1);
end method;


/* Events for suspends (CTRL-Z)
 */
define class <tty-suspend> (<tty-event>, <condition>)
end class;


/* Key events
 */
define class <tty-key> (<tty-event>)
  slot key-control? :: <boolean> = #f,
    init-keyword: control?:;
  slot key-character :: false-or(<byte-character>) = #f,
    init-keyword: character:;
  slot key-function :: false-or(<symbol>) = #f,
    init-keyword: function:;
end class;

define method key-character? (k :: <tty-key>)
 => (ischar? :: <boolean>);
  true?(k.key-character);
end method;


/* Activity lifecycle events
 */
define class <tty-activity-event> (<tty-event>)
end class;

define class <tty-activity-start> (<tty-activity-event>)
end class;

define class <tty-activity-finish> (<tty-activity-event>)
end class;

define class <tty-activity-pause> (<tty-activity-event>)
end class;

define class <tty-activity-resume> (<tty-activity-event>)
end class;
