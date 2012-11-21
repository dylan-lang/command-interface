module: dylan-user

define library cli
  use common-dylan;
  use source-records;
  use io;
  use c-ffi;
  use system;
  use strings;
end library;

define module tty
  use common-dylan;

  // we use streams and also wrap them
  use streams;
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
    import: { format-out };

  // tty
  export
    <tty>,
    tty-run,
    application-controlling-tty;

  // tty activities
  export
    <tty-activity>;

  // editor activity
  export
    <tty-editor>,
    editor-prompt,
    //editor-prompt-setter,
    editor-line,
    //editor-line-setter,

    editor-clear,

    editor-execute,
    editor-complete,

    editor-finish,

    editor-refresh-position,
    editor-refresh-line;
end module;

define module cli
  use common-dylan;
  use streams;
  use format;
  use print;
  use pprint;
  use strings;
  use file-system;
  use locators;
  use standard-io;
  use format-out;
  use operating-system;
  use source-records;

  use tty;
end module;

