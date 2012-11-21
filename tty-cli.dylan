module: cli

define class <tty-cli> (<tty-editor>)
end class;

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
    format(*standard-error*, "%s%s\n%s\n",
           n-spaces(size(editor-prompt(editor))),
           cli-annotate(src, le.error-srcoff),
           condition-to-string(le));
  exception (pe :: <cli-parse-error>)
    format(*standard-error*, "%s%s\n%s\n",
           n-spaces(size(editor-prompt(editor))),
           cli-annotate(src, token-srcloc(pe.error-token)),
           condition-to-string(pe));
  end;

  force-output(*standard-output*);
  force-output(*standard-error*);

  editor-refresh-line(editor);
end method;
