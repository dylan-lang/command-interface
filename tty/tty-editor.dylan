module: tty
synopsis: TTY line editor activity.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file COPYING

/* Line editor for TTYs
 *
 * This currently handles just a prompt and some simple editing and motion.
 *
 * Completion and execution can be implemented by inheritors.
 *
 */
define class <tty-editor> (<tty-activity>)
  slot editor-prompt :: <string> = "> ";

  slot editor-line :: <string> = "";
  slot editor-position :: <integer> = 0;

  slot editor-dirty-position? :: <boolean> = #f;
  slot editor-dirty-line? :: <boolean> = #f;

  slot editor-history-list :: <list> = #();
  slot editor-history-current :: false-or(<list>) = #f;
end class;

/* Finish the editor when paused
 */
define method tty-activity-event (editor :: <tty-editor>, event :: <tty-activity-pause>)
 => ();
  editor-finish(editor);
end method;

/* Perform full redraw when resumed
 */
define method tty-activity-event (editor :: <tty-editor>, event :: <tty-activity-resume>)
 => ();
  editor-refresh-line(editor);
  editor-maybe-refresh(editor);
end method;

/* Handle key events
 */
define method tty-activity-event (editor :: <tty-editor>, key :: <tty-key>)
  => ();
  let tty = activity-tty(editor);
  select (key-function(key))
    #"backspace" => editor-backspace(editor);
    #"refresh" => editor-refresh-line(editor);
    #"clear" => editor-clear(editor);
    #"cursor-right" => editor-move(editor, +1);
    #"cursor-left" => editor-move(editor, -1);
    #"quit" =>
      if (size(editor-line(editor)) = 0)
        tty-finish-activity(tty);
      end;
    #"enter" =>
      begin
        editor-complete-implicit(editor);
        editor-maybe-refresh(editor);
        editor-execute(editor);
      end;
    #"tab" => editor-complete(editor);
    otherwise =>
      begin
        if (key-control?(key))
          select (key-character(key))
            'A' => editor-jump(editor, 0);
            'E' => editor-jump(editor, size(editor-line(editor)));
            otherwise => #f;
          end;
        else
          if (key-character?(key))
            if (key-character(key) ~= ' ' | editor-complete-implicit(editor))
              editor-insert(editor, key-character(key));
            end;
          end;
        end;
      end;
  end;
  editor-maybe-refresh(editor);
  tty-flush(tty);
end method;

/* Finish use of the TTY
 *
 * This leaves the TTY on a clean line.
 *
 */
define method editor-finish (editor :: <tty-editor>)
 => ();
  let tty = activity-tty(editor);
  tty-cursor-column(tty, 0);
  tty-linefeed(tty);
end method;

/* Execute or act upon editor content
 */
define method editor-execute (editor :: <tty-editor>)
 => ();
  editor-finish(editor);
  editor-clear(editor);
end method;

/* Complete editor content at current position
 */
define method editor-complete (editor :: <tty-editor>)
 => ();
  editor-finish(editor);
  format-out("complete: \"%s\" at %d\n", editor-line(editor), editor-position(editor));
  editor-refresh-line(editor);
end method;

/* Complete editor content at current position silently (space completion)
 */
define method editor-complete-implicit (editor :: <tty-editor>)
 => (accepted? :: <boolean>);
  #f;
end method;


/* Refresh if needed
 */
define method editor-maybe-refresh (editor :: <tty-editor>)
 => ();
  let tty = activity-tty(editor);
  let prompt = editor-prompt(editor);
  if(editor-dirty-line?(editor))
    tty-cursor-column(tty, 0);
    tty-kill-whole-line(tty);
    tty-write(tty, prompt);
    tty-write(tty, editor-line(editor));
  end;
  if(editor-dirty-line?(editor) | editor-dirty-position?(editor))
    tty-cursor-column(tty, size(prompt) + editor-position(editor));
  end;
  editor-dirty-line?(editor) := #f;
  editor-dirty-position?(editor) := #f;
end method;

/* Request refresh of the entire line
 * Will also position the cursor
 */
define method editor-refresh-line (editor :: <tty-editor>)
 => ();
  editor.editor-dirty-line? := #t;
end method;

/* Request refresh of the cursor position
 */
define method editor-refresh-position (editor :: <tty-editor>)
 => ();
  editor.editor-dirty-position? := #t;
end method;

/* Clear the contents of the editor
 */
define method editor-clear (editor :: <tty-editor>)
 => ();
  editor-line(editor) := "";
  editor-position(editor) := 0;
  editor-refresh-line(editor);
end method;

/* Replace the given range with a replacement
 */
define method editor-replace
    (editor :: <tty-editor>, start-posn :: <integer>,
     end-posn :: <integer>, replacement :: <string>)
 => ();
  let str = editor-line(editor);
  // compute new string and position
  let new-str = replace-subsequence!
  (str, replacement, start:  start-posn, end: end-posn);
  let new-posn = start-posn + size(replacement);
  // apply things to editor
  editor-line(editor) := new-str;
  editor-position(editor) := new-posn;
  editor-refresh-line(editor);
end method;

/* Insert the given char at the given column
 */
define method editor-insert-at
    (editor :: <tty-editor>, char :: <byte-character>, column :: <integer>)
 => ();
  let old-line = editor-line(editor);
  let new-line = make(<byte-string>, size: size(old-line) + 1);
  for (i from 0 below column)
    new-line[i] := old-line[i];
  end;
  new-line[column] := char;
  for (i from column + 1 below size(new-line))
    new-line[i] := old-line[i - 1];
  end;
  editor-line(editor) := new-line;
  editor-refresh-line(editor);
end method;

/* Delete the character at the given column
 */
define method editor-delete-at
    (editor :: <tty-editor>, column :: <integer>)
 => ();
  let old-line = editor-line(editor);
  let new-line = make(<byte-string>, size: size(old-line) - 1);
  for (i from 0 below column)
    new-line[i] := old-line[i];
  end for;
  for (i from column below size(new-line))
    new-line[i] := old-line[i + 1];
  end for;
  editor-line(editor) := new-line;
  editor-refresh-line(editor);
end method;

/* Insert the given character at the current position
 */
define method editor-insert (editor :: <tty-editor>, char :: <character>)
 => ();
  editor-insert-at(editor, char, editor-position(editor));
  editor-position(editor) := editor-position(editor) + 1;
end method;

/* Delete char before current position
 */
define method editor-backspace (editor :: <tty-editor>)
 => ();
  if (editor-position(editor) > 0)
    editor-delete-at(editor, editor-position(editor) - 1);
    editor-position(editor) := editor-position(editor) - 1;
  end;
end method;

/* Jump to the given position
 */
define method editor-jump (editor :: <tty-editor>, column :: <integer>)
 => ();
  let total-len = size(editor-line(editor));
  if (column >= 0 & column <= total-len)
    tty-cursor-column(activity-tty(editor), column);
    editor-position(editor) := column;
    editor-refresh-position(editor);
  end;
end method;

/* Move relatively by the given number of columns
 */
define method editor-move (editor :: <tty-editor>, columns :: <integer>)
  let posn = editor-position(editor) + columns;
  if (posn < 0)
    posn := 0;
  end;
  if (posn > size(editor-line(editor)))
    posn := size(editor-line(editor));
  end;
  editor-jump(editor, posn);
end method;
