module: dylan-user
synopsis: Library and module declarations.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define library command-interface
  use common-dylan;
  use source-records;
  use io;
  use c-ffi;
  use system;
  use strings;
  use tty;

  export command-interface;
end library;

define module command-interface
  use common-dylan;

  // all over the place
  use standard-io;
  use strings;
  use format,
    import: { format };
  use format-out,
    import: { format-out, force-out,
              format-err, force-err };
  use streams,
    import: { force-output };
  use tty;
  // used by <command-file>
  use file-system;
  use locators;
  // used in source.dylan
  use source-records;
  // used by <tty-cli>
  use tty;

  export
    // source records
    <command-source>,
    <command-string-source>,
    source-string,
    <command-vector-source>,
    source-vector,
    // source locations
    <command-srcloc>,
    <command-srcoff>,
    // tokens
    <command-token>,
    token-type,
    token-string,
    token-srcloc,
    // completions
    <command-completion>,
    <command-completion-option>,
    make-completion,
    // source record ops
    command-tokenize,
    command-annotate,
    // errors
    <command-lexer-error>;

  export
    <command-parser>,
    // getters and setters
    parser-source,
    // operations
    parser-advance,
    parser-parse,
    parser-complete,
    parser-execute,
    parser-get-parameter,
    // errors
    <command-parse-error>,
    error-parser,
    error-token,
    <command-ambiguous-error>,
    <command-unknown-error>;

  export
    <command-node>,
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
    <command-root>,
    <command-symbol>,
    <command-command>,
    <command-wrapper>,
    <command-parameter>,
    <command-string>,
    <command-oneof>,
    parameter-name,
    parameter-required?,
    <command-file>;

  export
    <tty-command-shell>,
    tty-command-shell-main;

  export
    longest-common-prefix;

  export
    command-definer,
    command-root-definer;

end module;
