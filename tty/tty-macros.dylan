module: tty
synposis: TTY macros.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

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

/*
 * Helper for with-tty macro
 */
define method %with-tty(t :: <tty>, function :: <function>, #rest arguments)
  => ();
  // remember original streams and tty
  let oo = *standard-output*;
  let oe = *standard-error*;
  let ot = *current-tty*;
  block ()
    // finish previous tty and switch to new one
    if (ot)
      tty-finish(ot);
    end;
    *current-tty* := t;
    tty-start(t);
    // wrap stdio streams
    *standard-output* := make(<tty-stream>, inner-stream: tty-output(t));
    *standard-error* := make(<tty-stream>, inner-stream: tty-error(t) | tty-output(t));
    // call body function
    apply(function, arguments);
  cleanup
    // finish all remaining activities
    while (tty-activity(t))
      tty-finish-activity(t);
    end;
    // restore original streams and tty
    *standard-output* := oo;
    *standard-error* := oe;
    // finish tty and switch to previous one
    *current-tty* := ot;
    tty-finish(t);
    if (ot)
      tty-start(ot);
    end;
  end;
end;
