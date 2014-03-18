module: dylan-user
synopsis: Library and module declarations.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define library tty
  use common-dylan;
  use io;
  use c-ffi;
  use system;
  use strings;

  export tty;
end library;

define module tty
  use common-dylan;

  // we use streams and also wrap them
  use streams;
  use streams-internals, import: { accessor, accessor-fd };
  // we override stdio
  use standard-io;
  // the unix binding uses c-ffi
  use c-ffi;
  // for getting TERM and such
  use operating-system,
    import: { environment-variable };
  // these are not used much
  use format,
    import: { format };
  use format-out,
    import: { format-out, force-out };
  // whitespace?
  use strings;

  // tty
  export
    <tty>,
    with-tty,
    tty-activity,
    tty-start-activity,
    tty-finish-activity,
    tty-run,
    current-tty,
    application-controlling-tty;

  // tty activities
  export
    <tty-activity>,
    tty-activity-event;

  // tty events
  export
    <tty-event>,
    event-tty,
    <tty-key>,
    key-control?,
    key-character?,
    key-character,
    key-function,
    <tty-activity-event>,
    <tty-activity-start>,
    <tty-activity-finish>,
    <tty-activity-pause>,
    <tty-activity-resume>;

  // editor activity
  export
    <tty-editor>,
    // getters and setters
    editor-prompt,
    editor-prompt-setter,
    editor-line,
    editor-line-setter,
    editor-position,
    editor-position-setter,
    // text manipulation
    editor-clear,
    editor-replace,
    // relevant to users
    editor-finish,
    editor-execute,
    editor-complete,
    editor-complete-implicit,
    // XXX: need this?
    editor-refresh-position,
    editor-refresh-line;

  export
    <unix-tty>,
    unix-tty-type;

end module;
