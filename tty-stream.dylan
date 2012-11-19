module: cli

// This is required so we can convert 

define class <tty-stream> (<wrapper-stream>)
end class;

define method write-line
    (stream :: <tty-stream>, string :: <string>,
     #rest keys, #key start: _start, end: _end)
 => ();
  apply(write, stream, string, start: _start, end: _end, keys);
  new-line(stream);
end method;

define method new-line(stream :: <tty-stream>)
 => ();
  write(stream, stream.newline-sequence);
end method;

define method newline-sequence(stream :: <tty-stream>)
 => (s :: <string>);
  "\r\n";
end method;
