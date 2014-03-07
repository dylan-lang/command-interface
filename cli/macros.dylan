module: cli
synopsis: Macros for definining CLI grammar.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

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
           (?definitions) (?definitions) (?definitions) (?definitions) (?definitions)
         end }
end macro;

define macro cli-command-aux-definer
  { define cli-command-aux ?root:name (?symbols)
      (?definitions) (?bindings) (?implementation) (?keywords) (?parameters)
    end }
    => { begin
           let %root :: <cli-root> = ?root;
           let %symbols :: <list> = #(?symbols);
           let %handler = method (%parser :: <cli-parser>)
                           => ();
                            ?bindings;
                            ?implementation;
                          end method;
           let %command = root-define-command(%root, %symbols, handler: %handler, ?keywords);
           ?parameters
         end }

  // transform symbol list
  symbols:
    { } => { }
    { ?symbol:name ... } => { ?#"symbol", ... }

  // all definitions (syntax check)
  definitions:
    { } => { }
    { help ?text:expression; ...       } => { }
    { implementation ?:expression; ... } => { }
    { ?parameter-adjectives parameter ?:name, #rest ?parameter-options; ... } => { }
    { ?parameter-adjectives parameter ?:name :: ?type:expression, #rest ?parameter-options; ... } => { }

  // parameter bindings
  bindings:
    { } => { }
    { ?parameter-adjectives parameter ?:name, #rest ?parameter-options; ... }
      => { let ?name = parser-get-parameter(%parser, ?#"name"); ... }
    { ?parameter-adjectives parameter ?:name :: ?type:expression, #rest ?parameter-options; ... }
      => { let ?name = parser-get-parameter(%parser, ?#"name"); ... }
    { ?other:*; ... } => { ... }

  // command implementation
  implementation:
    { } => { }
    { implementation ?:expression; ... }
      => { ?expression; ... }
    { ?other:*; ... } => { ... }

  // definitions that expand into keywords
  keywords:
    { } => { }
    { help ?text:expression; ... }
      => { help: ?text, ... }
    { ?other:*; ... } => { ... }

  // definitions that define parameters
  parameters:
    { } => { }
    { ?parameter-adjectives parameter ?:name, #rest ?parameter-options; ... }
      => { make-param(%command, ?#"name", ?parameter-options, ?parameter-adjectives); ... }
    { ?parameter-adjectives parameter ?:name :: ?type:expression, #rest ?parameter-options; ... }
      => { make-param(%command, ?#"name", value-type: ?type, ?parameter-options, ?parameter-adjectives); ... }
    { ?other:*; ... } => { ... }

  // parameter adjectives
  parameter-adjectives:
    { } => { }
    { named ... } => { syntax: #"named", ... }
    { inline ... } => { syntax: #"inline", ... }
    { simple ... } => { syntax: #"simple", ... }

  // parameter options
  parameter-options:
    { #rest ?all:* }
      => { ?all }

end macro;
