module: cli

define abstract class <tty-activity> (<object>)
  slot activity-tty :: false-or(<tty>) = #f;
  slot activity-previous :: false-or(<tty-activity>) = #f;
end class;


define method tty-activity-start(a :: <tty-activity>)
 => ();
end method;

define method tty-activity-resume(a :: <tty-activity>)
 => ();
end method;

define method tty-activity-pause(a :: <tty-activity>)
 => ();
end method;

define method tty-activity-finish(a :: <tty-activity>)
 => ();
end method;


define method tty-activity-event(a :: <tty-activity>, e :: <tty-event>)
 => ();
end method;
