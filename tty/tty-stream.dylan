module: tty
synposis: TTY wrapper streams.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file COPYING

/* STDIO wrapper stream for TTY raw mode
 *
 * These are used to wrap stdio while the respective TTY
 * is in RAW mode so that we have an opportunity to expand
 * CR into CRLF.
 *
 * We only need to override all methods related to printing newlines.
 *
 */
define class <tty-stream> (<wrapper-stream>)
end class;

define method write-line
    (stream :: <tty-stream>, string :: <string>,
     #rest keys, #key start: _start, end: _end)
 => ();
  apply(write, stream, string, start: _start, end: _end, keys);
  new-line(stream);
end method;

define method new-line (stream :: <tty-stream>)
 => ();
  write(stream, stream.newline-sequence);
end method;

define method newline-sequence (stream :: <tty-stream>)
 => (s :: <string>);
  "\r\n";
end method;
