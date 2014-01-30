module: cli
synopsis: Macros for definining CLI grammar.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file COPYING

define macro cli-root-definer
  { define cli-root ?:name }
    => { define constant ?name = make(<cli-root>);
         begin
           root-add-bash-completion(?name);
           root-add-help(?name);
         end }
end macro;

define macro cli-command-definer
  { define cli-command ?root:name (?symbols:*)
      ?definitions:*
    end }
    => { define cli-command-aux ?root (?symbols)
           (?definitions) (?definitions) (?definitions)
         end }
end macro;

define macro cli-command-aux-definer
  { define cli-command-aux ?root:name (?symbols)
      (?definitions) (?keywords) (?parameters)
    end }
    => { begin
           let %root :: <cli-root> = ?root;
           let %symbols :: <list> = #(?symbols);
           let %command = root-define-command(%root, %symbols, ?keywords);
           ?parameters
         end }

  // transform symbol list
  symbols:
    { } => { }
    { ?symbol:name ... } => { ?#"symbol", ... }

  // all definitions (syntax check)
  definitions:
    { } => { }
    { ?definition; ... } => { }
  definition:
    { help ?text:expression       } => { }
    { implementation ?:expression } => { }
    { named  parameter ?:name     } => { }
    { inline parameter ?:name     } => { }
    { simple parameter ?:name     } => { }

  // definitions that expand into keywords
  keywords:
    { } => { }
    { ?keyword; ... } => { ?keyword, ... }
  keyword:
    { help ?text:expression }
      => { help: ?text }
    { implementation ?:expression }
      => { handler: method (p :: <cli-parser>)
                      => ();
                      ?expression
                    end method }
    { ?other:* } => { }

  // definitions that define parameters
  parameters:
    { } => { }
    { ?parameter; ... } => { ?parameter; ... }
  parameter:
    { named  parameter ?:name } => { make-named-param(%command, ?#"name")  }
    { inline parameter ?:name } => { make-inline-param(%command, ?#"name") }
    { simple parameter ?:name } => { make-simple-param(%command, ?#"name") }
    { ?other:* } => { #f }

end macro;
