module: tty

define abstract class <tty-activity> (<object>)
  slot activity-tty :: false-or(<tty>) = #f;
  slot activity-previous :: false-or(<tty-activity>) = #f;
end class;

define method tty-activity-event(a :: <tty-activity>, e :: <tty-event>)
 => ();
end method;
