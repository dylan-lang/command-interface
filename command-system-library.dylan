module: dylan-user
synopsis: Library and module declarations.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define library command-system
  use common-dylan;
  use source-records;
  use io;
  use c-ffi;
  use system;
  use strings;
  use tty;

  export command-system;
end library;

define module command-system
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
  use tty;
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
