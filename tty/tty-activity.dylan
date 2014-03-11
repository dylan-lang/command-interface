module: tty
synopsis: TTY activity abstraction.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

/* Activities are interactive components that use a TTY
 *
 * Activities receive key events which they are free to handle.
 *
 * While activity events are being delivered, stdio streams will be
 * redirected to the proper terminal streams.
 *
 * There are automatic flushes after each event.
 *
 * Activities have an android-like life cycle with the following events:
 *
 *  - START
 *    Called when an activity starts.
 *    No tty activity should be attempted.
 *
 *  - FINISH
 *    Called when an activity is finished
 *    or being finished. This is the final
 *    event for an activity. No tty activity
 *    should be attempted.
 *
 *  - PAUSE
 *    Called when an activity is subsumed
 *    by another activity or when the current
 *    activity is suspended (for SIGTSTP).
 *    Activities should relinquish control
 *    here and leave the TTY at a clean line.
 *    Also called before FINISH.
 *
 *  - RESUME
 *    Called when an activity resumes from
 *    paused state. Also called after START.
 *    After this call, the activity owns the TTY.
 *
 */
define abstract class <tty-activity> (<object>)
  slot activity-tty :: false-or(<tty>) = #f;
  slot activity-previous :: false-or(<tty-activity>) = #f;
end class;

/* Called to deliver an event to the activity
 *
 * Dispatch may be used to distinguish between event classes.
 *
 */
define open generic tty-activity-event (a :: <tty-activity>, e :: <tty-event>)
  => ();

define method tty-activity-event (a :: <tty-activity>, e :: <tty-event>)
 => ();
end method;
