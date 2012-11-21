module: tty

define class <tty-editor> (<tty-activity>)
  slot editor-prompt :: <string> = "> ";
  slot editor-line :: <string> = "";
  slot editor-position :: <integer> = 0;
  slot editor-history-list :: <list> = #();
  slot editor-history-current :: false-or(<list>) = #f;
end class;

define method tty-activity-resume(editor :: <tty-editor>)
 => ();
  editor-refresh-line(editor);
end method;

define method tty-activity-pause(editor :: <tty-editor>)
 => ();
  editor-finish(editor);
end method;

define method tty-activity-event(editor :: <tty-editor>, key :: <tty-key>)
  => ();
  select(key-function(key))
    #"backspace" => editor-backspace(editor);
    #"refresh" => editor-refresh-line(editor);
    #"clear" => editor-clear(editor);
    #"cursor-right" => editor-move(editor, +1);
    #"cursor-left" => editor-move(editor, -1);
    #"quit" =>
      if(size(editor-line(editor)) = 0)
        tty-finish-activity(activity-tty(editor));
      end;
    #"enter" => editor-execute(editor);
    #"tab" => editor-complete(editor);
    otherwise =>
      begin
        if(key-control?(key))
          select(key-character(key))
            'A' => editor-jump(editor, 0);
            'E' => editor-jump(editor, size(editor-line(editor)));
            otherwise => #f;
          end;
        else
          if(key-character?(key))
            editor-insert(editor, key-character(key));
          end;
        end;
      end;
  end;
end method;

define method editor-finish(editor :: <tty-editor>)
 => ();
  let tty = activity-tty(editor);
  tty-linefeed(tty);
  tty-cursor-column(tty, 0);
end method;

define method editor-execute(editor :: <tty-editor>)
 => ();
  editor-finish(editor);
  editor-clear(editor);
end method;

define method editor-complete(editor :: <tty-editor>)
 => ();
  editor-finish(editor);
  format-out("complete: \"%s\" at %d\n", editor-line(editor), editor-position(editor));
  editor-refresh-line(editor);
end method;

define method editor-refresh-line(editor :: <tty-editor>)
 => ();
  let tty = activity-tty(editor);
  let prompt = editor-prompt(editor);
  tty-cursor-column(tty, 0);
  tty-kill-whole-line(tty);
  tty-write(tty, prompt);
  tty-write(tty, editor-line(editor));
  editor-refresh-position(editor);
end method;

define method editor-refresh-position(editor :: <tty-editor>)
 => ();
  let tty = activity-tty(editor);
  let prompt = editor-prompt(editor);
  tty-cursor-column(tty, size(prompt) + editor-position(editor));
end method;

define method editor-clear(editor :: <tty-editor>)
 => ();
  editor-line(editor) := "";
  editor-position(editor) := 0;
  editor-refresh-line(editor);
end method;

define method editor-insert-at
    (editor :: <tty-editor>, char :: <byte-character>, column :: <integer>)
 => ();
  let old-line = editor-line(editor);
  let new-line = make(<byte-string>, size: size(old-line) + 1);
  for(i from 0 below column)
    new-line[i] := old-line[i];
  end;
  new-line[column] := char;
  for(i from column + 1 below size(new-line))
    new-line[i] := old-line[i - 1];
  end;
  editor-line(editor) := new-line;
  editor-position(editor) := column + 1;
  editor-refresh-line(editor);
end method;

define method editor-delete-at
    (editor :: <tty-editor>, column :: <integer>)
 => ();
  let old-line = editor-line(editor);
  let new-line = make(<byte-string>, size: size(old-line) - 1);
  for(i from 0 below column)
    new-line[i] := old-line[i];
  end for;
  for(i from column below size(new-line))
    new-line[i] := old-line[i + 1];
  end for;
  editor-line(editor) := new-line;
  editor-position(editor) := column;
  editor-refresh-line(editor);
end method;

define method editor-insert(editor :: <tty-editor>, char :: <character>)
 => ();
  editor-insert-at(editor, char, editor-position(editor));
end method;

define method editor-backspace(editor :: <tty-editor>)
 => ();
  if(editor-position(editor) > 0)
    editor-delete-at(editor, editor-position(editor) - 1);
  end;
end method;

define method editor-jump(editor :: <tty-editor>, column :: <integer>)
 => ();
  let total-len = size(editor-line(editor));
  if(column >= 0 & column <= total-len)
    tty-cursor-column(activity-tty(editor), column);
    editor-position(editor) := column;
    editor-refresh-position(editor);
  end;
end method;

define method editor-move(editor :: <tty-editor>, columns :: <integer>)
  let posn = editor-position(editor) + columns;
  if(posn < 0)
    posn := 0;
  end;
  if(posn > size(editor-line(editor)))
    posn := size(editor-line(editor));
  end;
  editor-jump(editor, posn);
end method;
