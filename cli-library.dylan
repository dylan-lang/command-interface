module: dylan-user
synopsis: Library and module declarations.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file COPYING

define library cli
  use common-dylan;
  use source-records;
  use io;
  use c-ffi;
  use system;
  use strings;

  export cli;
  export tty;
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
    import: { format-out, force-out };

  // tty
  export
    <tty>,
    tty-run,
    tty-activity,
    tty-start-activity,
    tty-finish-activity,
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

define module cli
  use common-dylan;

  // all over the place
  use standard-io;
  use strings;
  use format,
    import: { format };
  use format-out,
    import: { format-out, force-out };
  use streams,
    import: { force-output };
  // used by <cli-file>
  use file-system;
  use locators;
  // used in source.dylan
  use source-records;
  // used by <tty-cli>
  use tty;

  export
    // source records
    <cli-source>,
    <cli-string-source>,
    source-string,
    <cli-vector-source>,
    source-vector,
    // source locations
    <cli-srcloc>,
    <cli-srcoff>,
    // tokens
    <cli-token>,
    token-type,
    token-string,
    token-srcloc,
    // source record ops
    cli-tokenize,
    cli-annotate,
    // errors
    <cli-lexer-error>;

  export
    <cli-parser>,
    // getters and setters
    parser-source,
    // operations
    parser-advance,
    parser-parse,
    parser-complete,
    parser-execute,
    parser-get-parameter,
    // errors
    <cli-parse-error>,
    error-parser,
    error-token,
    <cli-ambiguous-error>,
    <cli-unknown-error>;

  export
    <cli-node>,
    // getters and setters
    node-hidden?,
    node-repeatable?,
    node-priority,
    // operations
    node-add-successor,
    node-accept,
    node-complete,
    node-match,
    // subclasses
    <cli-root>,
    <cli-symbol>,
    <cli-command>,
    <cli-wrapper>,
    <cli-parameter>,
    <cli-string>,
    <cli-oneof>,
    parameter-name,
    parameter-mandatory?,
    <cli-file>;

  export
    <tty-cli>,
    tty-cli-main;

  export
    root-define-command,
    root-add-help,
    root-add-bash-completion,
    make-named-param,
    make-inline-param,
    make-simple-param;

  export
    longest-common-prefix;

  export
    cli-root-definer,
    cli-command-definer;

end module;
