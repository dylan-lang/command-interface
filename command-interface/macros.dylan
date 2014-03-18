module: command-interface
synopsis: Macros for definining CLI grammar.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define macro command-root-definer
  { define command-root ?:name }
    => { define constant ?name = make(<command-root>);
         begin
           root-add-bash-completion(?name);
           root-add-help(?name);
         end }
end macro;

define macro command-definer
  { define command ?symbols:* (?root:name)
      ?definitions:*
    end }
    => { define command-aux (?symbols) (?root)
           (?definitions) (?definitions) (?definitions) (?definitions) (?definitions)
         end }
end macro;

define macro command-aux-definer
  { define command-aux (?symbols) (?root:name)
      (?definitions) (?bindings) (?implementation) (?keywords) (?parameters)
    end }
    => { begin
           let %root :: <command-root> = ?root;
           let %symbols :: <list> = #(?symbols);
           let %handler = method (%parser :: <command-parser>)
                           => ();
                            ?bindings;
                            ?implementation;
                          end method;
           let %command = build-command(%root, %symbols, handler: %handler, ?keywords);
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
      => { build-parameter(%command, ?#"name", ?parameter-options, ?parameter-adjectives); ... }
    { ?parameter-adjectives parameter ?:name :: ?type:expression, #rest ?parameter-options; ... }
      => { build-parameter(%command, ?#"name", value-type: ?type, ?parameter-options, ?parameter-adjectives); ... }
    { ?other:*; ... } => { ... }

  // parameter adjectives
  parameter-adjectives:
    { } => { }
    { named ... } => { syntax: #"named", ... }
    { simple ... } => { syntax: #"simple", ... }

  // parameter options
  parameter-options:
    { #rest ?all:* }
      => { ?all }

end macro;
