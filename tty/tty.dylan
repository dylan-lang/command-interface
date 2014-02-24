module: tty
synopsis: TTY base class and generics.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file COPYING

/* Numeric parser state for ANSI parser
 */
define constant <tty-state> = <integer>;
define constant $tty-state-plain = 0;
define constant $tty-state-esc   = 1;
define constant $tty-state-csi   = 2;

/* Base class of TTYs
 *
 * This handles I/O for the TTY, including
 * parsing and generation of ANSI code sequences.
 *
 * It also handles activity lifecycle.
 */
define abstract class <tty> (<object>)
  slot tty-activity :: false-or(<tty-activity>) = #f,
    init-keyword: activity:;

  slot tty-state :: <tty-state> = $tty-state-plain;

  slot tty-input :: <stream>,
    required-init-keyword: input:;
  slot tty-output :: <stream>,
    required-init-keyword: output:;
  slot tty-error :: false-or(<stream>) = #f,
    init-keyword: error:;
end class;

/* Represents the "current" tty for this thread
 */
define thread variable *current-tty* :: false-or(<tty>) = #f;

/* Returns the current tty if called from within the event loop
 */
define function current-tty()
  => (tty :: false-or(<tty>));
  *current-tty*;
end function;

/* Prepare terminal for use
 */
define generic tty-start (t :: <tty>)
 => ();

/* Clean up terminal after use
 */
define generic tty-finish (t :: <tty>)
 => ();

/* Loop over TTY events
 */
define method tty-run (t :: <tty>, a :: <tty-activity>)
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
    block ()
      tty-start-activity(t, a);
      iterate read-more()
        let c = read-element(tty-input(t), on-end-of-stream: #f);
        if (c)
          tty-feed(t, c);
          tty-flush(t);
          if (tty-activity(t))
            read-more();
          end;
        end;
      end;
    cleanup
      while (tty-activity(t))
        tty-finish-activity(t);
      end;
    end;
  cleanup
    *standard-output* := oo;
    *standard-error* := oe;
    *current-tty* := ot;
    tty-finish(t);
    if (ot)
      tty-start(ot);
    end;
  end;
end method;

/* Make and dispatch a TTY event
 */
define method tty-event (t :: <tty>, a :: <tty-activity>, class :: subclass(<tty-activity-event>))
 => ();
  tty-activity-event(a, make(class, tty: t, activity: a));
end method;

/* Begin executing the given TTY activity
 *
 * This will pause the current activity and continue in the new one.
 */
define method tty-start-activity (t :: <tty>, a :: <tty-activity>)
 => ();
  let previous = tty-activity(t);
  // pause previous
  if (previous)
    tty-event(t, previous, <tty-activity-pause>);
    activity-tty(a) := #f;
  end;
  // set activity slots
  activity-tty(a) := t;
  activity-previous(a) := previous;
  // activity is now current
  tty-activity(t) := a;
  // callbacks
  tty-event(t, a, <tty-activity-start>);
  tty-event(t, a, <tty-activity-resume>);
  // flush in case of output
  tty-flush(t);
end method;

/* Begin executing the given TTY activity
 *
 * This will finish the current activity and continue in the previous one.
 */
define method tty-finish-activity (t :: <tty>)
 => ();
  let a = tty-activity(t);
  if (a)
    let previous = activity-previous(a);
    // callbacks
    tty-event(t, a, <tty-activity-pause>);
    tty-event(t, a, <tty-activity-finish>);
    // pop the activity
    tty-activity(t) := previous;
    // clear activity slots
    activity-tty(a) := #f;
    activity-previous(a) := #f;
    // resume previous
    if (previous)
      activity-tty(previous) := t;
      tty-event(t, previous, <tty-activity-resume>);
    end;
  end;
end method;

/* Flush all output for the TTY
 */
define method tty-flush (t :: <tty>)
  force-output(tty-output(t));
  if (tty-error(t))
    force-output(tty-error(t));
  end;
end method;

define method tty-dispatch-event (t :: <tty>, e :: <tty-event>)
 => ();
  if (tty-activity(t))
    tty-activity-event(tty-activity(t), e);
  else
    if (instance?(e, <tty-key>))
      format-out("Key %s%s (function %s)\n",
                 if (key-control?(e)) "ctrl-" else "" end,
                 key-character(e) | "",
                 key-function(e));
    else
      format-out("Event %=\n", e);
    end;
  end;

  if (instance?(e, <condition>))
    signal(e);
  end;
end method;

define method tty-feed (t :: <tty>, c :: <byte-character>)
 => ();
  tty-state(t) :=
    select (tty-state(t))
      $tty-state-plain =>
        tty-feed-plain(t, c);
      $tty-state-esc =>
        tty-feed-esc(t, c);
      $tty-state-csi =>
        tty-feed-csi(t, c);
    end;
end method;

define method tty-feed-plain (t :: <tty>, c :: <byte-character>)
 => (new-state :: <tty-state>);
  select (c)
    $ctrl-char-escape => $tty-state-esc;

    $ctrl-char-interrupt =>
      begin
        tty-dispatch-event(t, make(<tty-interrupt>, tty: t));
        $tty-state-plain;
      end;

    $ctrl-char-suspend =>
      begin
        tty-dispatch-event(t, make(<tty-suspend>, tty: t));
        $tty-state-plain;
      end;

    otherwise =>
      begin
        tty-dispatch-event
          (t, make(<tty-key>,
                   tty: t,
                   control?: is-ctrl-char?(c),
                   function: char-function(c),
                   character: char-character(c)));
        $tty-state-plain;
      end;
  end;
end method;

define method tty-feed-esc (t :: <tty>, c :: <byte-character>)
 => (new-state :: <tty-state>);
  select (c)
    // ANSI sequence
    '['       => $tty-state-csi;
    // fall back to plain
    otherwise => $tty-state-plain;
  end;
end method;

define method tty-feed-csi (t :: <tty>, c :: <byte-character>)
 => (new-state :: <tty-state>);
  select (c)
    // cursor events
    'A', 'B', 'C', 'D' =>
      begin
        tty-dispatch-event
          (t, make(<tty-key>,
                   tty: t,
                   function:
                     select (c)
                       'A' => #"cursor-up";
                       'B' => #"cursor-down";
                       'C' => #"cursor-right";
                       'D' => #"cursor-left";
                     end));
        $tty-state-plain;
      end;
    // fall back to plain
    otherwise => $tty-state-plain;
  end;
end method;

define constant $ansi-csi = "\<1b>[";

define method tty-write (t :: <tty>, s :: <string>)
  => ();
  write(tty-output(t), s);
end method;

define method tty-format-csi (t :: <tty>, s :: <string>, #rest args)
 => ();
  apply(format, tty-output(t), concatenate($ansi-csi, s), args);
end method;

define method tty-kill-whole-line (t :: <tty>)
  => ();
  tty-format-csi(t, "%dK", 2);
end method;

define method tty-cursor-column (t :: <tty>, column :: <integer>)
  => ();
  tty-format-csi(t, "%dG", column + 1);
end method;

define method tty-linefeed (t :: <tty>)
  => ();
  tty-write(t, "\r\n");
end method;
