module: tty

define constant $char-delete = as(<byte-character>, 127);

// mask for converting to a ctrl char
define constant $ctrl-char-mask = #x1f;

// escape
define constant $ctrl-char-escape = ctrl-char('[');

// flow control
define constant $ctrl-char-pause = ctrl-char('s');
define constant $ctrl-char-resume = ctrl-char('q');

// process control
define constant $ctrl-char-status  = ctrl-char('t');
define constant $ctrl-char-interrupt = ctrl-char('c');
define constant $ctrl-char-suspend   = ctrl-char('z');

// other operations
define constant $ctrl-char-tab = ctrl-char('i');
define constant $ctrl-char-nak = ctrl-char('u');
define constant $ctrl-char-bel = ctrl-char('b');
define constant $ctrl-char-eot = ctrl-char('d');
define constant $ctrl-char-bs = ctrl-char('h');
define constant $ctrl-char-ff = ctrl-char('l');
define constant $ctrl-char-lf = ctrl-char('j');
define constant $ctrl-char-cr = ctrl-char('m');


define function ctrl-char (c :: <byte-character>)
 => (ctrl-char :: <byte-character>);
  as(<byte-character>,
     logand($ctrl-char-mask, as(<integer>, c)));
end function;

define function is-ctrl-char? (c :: <byte-character>)
 => (ctrl? :: <boolean>);
  as(<integer>, c) < #x20;
end function;

define function ctrl-char-character (c :: <byte-character>)
 => (character :: <byte-character>);
  if (is-ctrl-char?(c))
    as(<byte-character>,
       #x40 + as(<integer>, c));
  else
    c;
  end;
end function;

define function char-character (c :: <byte-character>)
 => (char :: false-or(<byte-character>));
  if (is-ctrl-char?(c))
    ctrl-char-character(c);
  else
    if (c == $char-delete)
      #f;
    else
      c;
    end;
  end;
end function;

define function char-function (c :: <byte-character>)
 => (key :: false-or(<symbol>));
  select (c)
    $ctrl-char-pause => #"pause";
    $ctrl-char-resume => #"resume";

    $ctrl-char-interrupt => #"interrupt";
    $ctrl-char-suspend => #"suspend";
    $ctrl-char-status => #"status";

    $ctrl-char-cr, $ctrl-char-lf => #"enter";
    $ctrl-char-bs, $char-delete => #"backspace";
    $ctrl-char-ff => #"refresh";
    $ctrl-char-tab => #"tab";

    $ctrl-char-eot => #"quit";
    $ctrl-char-bel => #"bell";
    $ctrl-char-nak => #"clear";

    otherwise => #f;
  end;
end function;
