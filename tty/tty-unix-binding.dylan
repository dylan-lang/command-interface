module: tty
synopsis: Binding for UNIX tcsetattr.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

/* UNIX representation of various TTY attributes
 */
define c-subtype <%unix-termios> (<c-void*>)
end;

/* Keep a RAW termios around for convenience
 */
define constant $unix-termios-raw =
  begin
    let termios = %unix-make-termios();
    %unix-cfmakeraw(termios);
    termios;
  end;

/* Check if the given FD revers to a UNIX TTY
 */
define c-function %unix-isatty
  parameter fd :: <c-int>;
  result code :: <c-int>;
  c-name: "isatty";
end;

/* Initialize the given termios as RAW
 */
define c-function %unix-cfmakeraw
  parameter termios :: <%unix-termios>;
  c-name: "cfmakeraw";
end;

/* Capture the attributes of the given TTY
 */
define c-function %unix-tcgetattr
  parameter fd :: <c-int>;
  parameter termios :: <%unix-termios>;
  result code :: <c-int>;
  c-name: "tcgetattr";
end;

/* Allocate a zero-initialized termios
 */
define c-function %unix-make-termios
  result termios :: <%unix-termios>;
  c-name: "unix_make_termios";
end;

/* Apply the given termios to the given TTY
 *
 * This will not flush before applying.
 */
/*
define c-function %unix-tcsetattr-now
  parameter fd :: <c-int>;
  parameter termios :: <%unix-termios>;
  result code :: <c-int>;
  c-name: "unix_tcsetattr_now";
end;
*/

/* Apply the given termios to the given TTY
 *
 * This will flush OUTPUT before applying.
 */
define c-function %unix-tcsetattr-drain
  parameter fd :: <c-int>;
  parameter termios :: <%unix-termios>;
  result code :: <c-int>;
  c-name: "unix_tcsetattr_drain";
end;

/* Apply the given termios to the given TTY
 *
 * This will flush OUTPUT and INPUT before applying.
 */
/*
define c-function %unix-tcsetattr-flush
  parameter fd :: <c-int>;
  parameter termios :: <%unix-termios>;
  result code :: <c-int>;
  c-name: "unix_tcsetattr_flush";
end;
*/
