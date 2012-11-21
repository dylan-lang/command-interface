module: tty

define constant $unix-termios-raw =
  begin
    let termios = %unix-make-termios();
    %unix-cfmakeraw(termios);
    termios;
  end;

define c-subtype <%unix-termios> (<c-void*>)
end;

define c-function %unix-isatty
  parameter fd :: <c-int>;
  result code :: <c-int>;
  c-name: "isatty";
end;

define c-function %unix-cfmakeraw
  parameter termios :: <%unix-termios>;
  c-name: "cfmakeraw";
end;

define c-function %unix-tcgetattr
  parameter fd :: <c-int>;
  parameter termios :: <%unix-termios>;
  result code :: <c-int>;
  c-name: "tcgetattr";
end;

define c-function %unix-make-termios
  result termios :: <%unix-termios>;
  c-name: "unix_make_termios";
end;

define c-function %unix-tcsetattr-now
  parameter fd :: <c-int>;
  parameter termios :: <%unix-termios>;
  result code :: <c-int>;
  c-name: "unix_tcsetattr_now";
end;

define c-function %unix-tcsetattr-drain
  parameter fd :: <c-int>;
  parameter termios :: <%unix-termios>;
  result code :: <c-int>;
  c-name: "unix_tcsetattr_drain";
end;

define c-function %unix-tcsetattr-flush
  parameter fd :: <c-int>;
  parameter termios :: <%unix-termios>;
  result code :: <c-int>;
  c-name: "unix_tcsetattr_flush";
end;
