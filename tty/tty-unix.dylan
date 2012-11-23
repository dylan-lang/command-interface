module: tty
synopsis: Support for UNIX TTYs in RAW mode
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file COPYING

/* UNIX TTYs
 *
 * These only work for real UNIX ttys and use
 * the UNIX terminal infrastructure.
 */
define class <unix-tty> (<tty>)
  slot unix-tty-type :: <string>,
    required-init-keyword: type:;

  slot unix-tty-initial-termios :: false-or(<%unix-termios>) = #f;
end class;

/* Get the file descriptor of the given TTY
 */
define method tty-file-descriptor (t :: <unix-tty>)
 => (fd :: <integer>);
  0; // XXX take from input stream
end method;

/* Initialize the TTY for use
 */
define method tty-start (t :: <unix-tty>)
 => ();
  unless (unix-tty-initial-termios(t))
    tty-flush(t);
    unix-tty-initial-termios(t) := unix-tty-get-termios(t);
    unix-tty-set-termios(t, $unix-termios-raw);
  end;
end method;

/* Reset the TTY to state before start
 */
define method tty-finish (t :: <unix-tty>)
 => ();
  if (unix-tty-initial-termios(t))
    tty-flush(t);
    unix-tty-set-termios(t, unix-tty-initial-termios(t));
    unix-tty-initial-termios(t) := #f;
  end;
end method;

/* Capture the attributes of the given TTY
 */
define method unix-tty-get-termios (t :: <unix-tty>)
 => (m :: <%unix-termios>);
  let termios = %unix-make-termios();
  // XXX return value
  %unix-tcgetattr(tty-file-descriptor(t), termios);
  termios;
end method;

/* Set the attributes of the given TTY
 */
define method unix-tty-set-termios (t :: <unix-tty>, m :: <%unix-termios>)
 => ();
  // XXX return value
  %unix-tcsetattr-drain(tty-file-descriptor(t), m);
end method;

/* Reference to the controlling tty, if there is one
 */
define variable *controlling-tty*
  :: false-or(<unix-tty>) = #f;

/* Get the UNIX controlling tty of the current process
 *
 * This is the TTY that is associated with stdio.
 */
define function application-controlling-tty ()
 => (t :: <tty>);
  unless (*controlling-tty*)
    *controlling-tty* := make-controlling-tty();
    register-application-exit-function(finish-controlling-tty);
  end;
  *controlling-tty*;
end function;

/* Construct a TTY for the controlling tty
 */
define function make-controlling-tty ()
 => (t :: <tty>);
  let type = environment-variable("TERM") | "vt102";
  make(<unix-tty>,
       input: *standard-input*,
       output: *standard-output*,
       error: *standard-error*,
       type: type)
end function;

/* Callback for cleaning up controlling terminal state via atexit()
 */
define function finish-controlling-tty ()
 => ();
  if (*controlling-tty*)
    tty-finish(*controlling-tty*);
  end;
end function;
