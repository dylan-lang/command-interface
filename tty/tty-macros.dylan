module: tty

/*
 * Run body in context of tty
 */
define macro with-tty
  { with-tty (?tty:expression)
      ?:body
    end }
    => { begin
           local method %code () => ()
                   ?body
                 end;
           %with-tty(?tty, %code);
         end }
end macro;

define method %with-tty(t :: <tty>, function :: <function>, #rest arguments)
  => ();
  let oo = *standard-output*;
  let oe = *standard-error*;
  let ot = *current-tty*;
  block ()
    if (ot)
      tty-finish(ot);
    end;
    *current-tty* := t;
    tty-start(t);
    *standard-output* := make(<tty-stream>, inner-stream: tty-output(t));
    *standard-error* := make(<tty-stream>, inner-stream: tty-error(t) | tty-output(t));
    apply(function, arguments);
  cleanup
    while (tty-activity(t))
      tty-finish-activity(t);
    end;
    *standard-output* := oo;
    *standard-error* := oe;
    *current-tty* := ot;
    tty-finish(t);
    if (ot)
      tty-start(ot);
    end;
  end;
end;
