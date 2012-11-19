module: cli

define class <tty-cli> (<tty-editor>)
end class;

define function tty-cli-annotate(editor, src, location)
  => ();
  // start on a fresh line
  new-line(*standard-error*);
  // print error mark line
  let marks = cli-annotate(src, location);
  write(*standard-error*, n-spaces(size(editor-prompt(editor))));
  write(*standard-error*, marks);
  new-line(*standard-error*);
end function;

define method editor-execute(editor :: <tty-cli>)
 => ();
  editor-finish(editor);

  let str = editor-line(editor);
  let src = make(<cli-string-source>, string: str);
  let parser = make(<cli-parser>, source: src, initial-node: $cli-root);  

  block ()
    let tokens = cli-tokenize(src);
    parser-parse(parser, tokens);
    parser-execute(parser);
    editor-clear(editor);
  exception (le :: <cli-lexer-error>)
    // print marks
    tty-cli-annotate(editor, src, le.error-srcoff);
    // print condition
    apply(format, *standard-error*,
          condition-format-string(le),
          condition-format-arguments(le));
    // flush
    force-output(*standard-error*);
  exception (pe :: <cli-parse-error>)
    // print marks
    tty-cli-annotate(editor, src, token-srcloc(pe.error-token));
    // print condition
    apply(format, *standard-error*,
          condition-format-string(pe),
          condition-format-arguments(pe));
    // flush
    force-output(*standard-error*);
  end;

  editor-refresh-line(editor);
end method;
