module: command-interface
synopsis: CLI node classes and functions.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define constant $command-priority-minimum   = -10000;
define constant $command-priority-parameter = -10;
define constant $command-priority-default   =  0;


/* Grammar node for the CLI
 *
 * These form a digraph with circles through their SUCCESSORS
 * field. Cycles can only occur through nodes that are REPEATABLE,
 * so the graph can be treated like a DAG when repeatable nodes
 * are ignored or visited only once.
 *
 * Each node represents one command token.
 *
 * Important operations:
 *
 *  Matching allows the parser to check if a given node is
 *  a valid partial or complete word for this node.
 *
 *  Completion allows the parser to generate possible
 *  words for a node. The parser may provide a partial token
 *  to limit and direct completion.
 *
 *  Accepting happens when the parser accepts a token for
 *  a node. During this, parameters add their values and
 *  commands install their handlers.
 *
 */
define abstract class <parse-node> (<object>)
  /* possible successor nodes (collected while building) */
  slot node-successors :: <list> = #(),
    init-keyword: successors:;
  /* match and completion priority */
  constant slot node-priority :: <integer> = $command-priority-default,
    init-keyword: priority:;
  /* hidden nodes are not completed */
  constant slot node-hidden? :: <boolean> = #f,
    init-keyword: hidden?:;
  /* repeatable nodes may re-appear */
  constant slot node-repeatable? :: <boolean> = #f,
    init-keyword: repeatable?:;
  /* don't repeat if this node is already present */
  constant slot node-repeat-marker :: false-or(<parse-node>) = #f,
    init-keyword: repeat-marker:;
end class;

/* Generate completions for the given node
 *
 * May or may not be provided a partial token.
 */
define open generic node-complete (node :: <parse-node>, parser :: <command-parser>, token :: false-or(<command-token>))
 => (completions :: <command-completion>);

/* Check if the given token matches this node partially or completely
 */
define open generic node-match (node :: <parse-node>, parser :: <command-parser>, token :: <command-token>)
 => (matched? :: <boolean>);

/* Accept the given node with the given token as data
 *
 * This is where parameters do conversion and command handlers are added.
 */
define open generic node-accept ( node :: <parse-node>, parser :: <command-parser>, token :: <command-token>)
 => ();


/* Is the node acceptable as next node in given parser state?
 *
 * This prevents non-repeatable parameters from being added again.
 *
 * Note how we also check for the repeat-marker of the node for
 * cases where another node can preclude our occurrence.
 */
define method node-acceptable? (node :: <parse-node>, parser :: <command-parser>)
 => (acceptable? :: <boolean>);
  if (node-repeatable?(node))
    #t
  else
    ~member?(node, parser-nodes(parser))
      & (node-repeat-marker(node) == #f
           | ~member?(node-repeat-marker(node), parser-nodes(parser)));
  end
end method;

/* Add a possible successor node
 */
define method node-add-successor (node :: <parse-node>, successor :: <parse-node>)
 => (successor :: <parse-node>);
  node-successors(node) := add(node-successors(node), successor);
  successor;
end method;

/* Default matcher (always false)
 */
define method node-match (node :: <parse-node>, parser :: <command-parser>, token :: <command-token>)
 => (matched? :: <boolean>);
  #f
end;

/* Default completer (no results)
 */
define method node-complete (node :: <parse-node>, parser :: <command-parser>, token :: false-or(<command-token>))
 => (completion :: <command-completion>);
  make-completion(node, token, exhaustive?: #t);
end method;

/* Default acceptor (no-op)
 */
define method node-accept (node :: <parse-node>, parser :: <command-parser>, token :: <command-token>)
 => ();
end method;



/* Root of a command hierarchy.
 *
 * May not be completed or matched.
 */
define class <root-node> (<parse-node>)
end class;

define method node-match (node :: <root-node>, parser :: <command-parser>, token :: <command-token>)
 => (matched? :: <boolean>);
  error("BUG: Tried to match a CLI root node");
end;

define method node-complete (node :: <root-node>, parser :: <command-parser>, token :: false-or(<command-token>))
 => (completions :: <command-completion>);
  error("BUG: Tried to complete a CLI root node");
end method;


/* A fixed string
 *
 * Used to build commands and parameter prefixes.
 */
define class <symbol-node> (<parse-node>)
  slot node-symbol :: <symbol>,
    init-keyword: symbol:;
end class;

define method print-object(object :: <symbol-node>, stream :: <stream>) => ();
  format(stream, "%s", node-symbol(object));
end method;

define method node-match (node :: <symbol-node>, parser :: <command-parser>, token :: <command-token>)
 => (matched? :: <boolean>);
  starts-with?(as(<string>, node-symbol(node)),
               as-lowercase(token-string(token)));
end method;

define method node-complete (node :: <symbol-node>, parser :: <command-parser>, token :: false-or(<command-token>))
 => (completion :: <command-completion>);
  make-completion(node, token,
                  exhaustive?: #t,
                  complete-options: list(as(<string>, node-symbol(node))));
end method;


/*
 * Commands are symbols with a handler and parameter requirements
 */
define open class <command-node> (<symbol-node>)
  /* help source for the command */
  constant slot command-help :: false-or(<string>) = #f,
    init-keyword: help:;
  /* handler function */
  constant slot command-handler :: false-or(<function>) = #f,
    init-keyword: handler:;
  /* parameters (collected while building) */
  slot command-parameters :: <list> = #();
  /* all flag parameters */
  slot command-flag-parameters :: <list> = #();
  /* all named parameters */
  slot command-named-parameters :: <list> = #();
  /* all simple parameters */
  slot command-simple-parameters :: <list> = #();
end class;

define method print-object(object :: <command-node>, stream :: <stream>) => ();
  format(stream, "%s - %s", node-symbol(object), command-help(object));
end method;

define method node-accept (node :: <command-node>, parser :: <command-parser>, token :: <command-token>)
 => ();
  if (command-handler(node))
    parser-push-command(parser, node);
  end
end method;

define method command-add-parameter (node :: <command-node>, parameter :: <parameter-node>)
 => ();
  command-parameters(node) := add!(command-parameters(node), parameter);
  select (parameter-kind(parameter))
    #"flag" =>
      command-flag-parameters(node) := add!(command-flag-parameters(node), parameter);
    #"named" =>
      command-named-parameters(node) := add!(command-named-parameters(node), parameter);
    #"simple" =>
      command-simple-parameters(node) := add!(command-simple-parameters(node), parameter);
  end;
end method;


/* Wrappers allow wrapping another command
 *
 * This is used for the "help" command so it can complete normal commands.
 *
 * They will have the successors of the given WRAPPER-ROOT.
 *
 */
define class <wrapper-node> (<command-node>)
  slot wrapper-root :: <parse-node>,
    init-keyword: root:;
end class;

define method node-successors (node :: <wrapper-node>)
 => (successors :: <sequence>);
  concatenate(node-successors(wrapper-root(node)), next-method());
end method;

/* Syntactical kinds of parameters
 */
define constant <parameter-kind> = one-of(#"simple", #"named", #"flag");

/* A captured parameter
 */
define open abstract class <parameter-node> (<parse-node>)
  constant slot parameter-name :: <symbol>,
    init-keyword: name:;
  constant slot parameter-kind :: <parameter-kind> = #"named",
    init-keyword: kind:;
  constant slot parameter-help :: false-or(<string>) = #f,
    init-keyword: help:;
  constant slot parameter-command :: false-or(<command-node>) = #f,
    init-keyword: command:;
  constant slot parameter-required? :: <boolean> = #f,
    init-keyword: required?:;
  constant slot parameter-value-type :: <type> = <string>,
    init-keyword: value-type:;
end class;

/* Parameters can be converted to values
 *
 * By default they convert to simple strings.
 */
define method parameter-convert (parser :: <command-parser>, node :: <parameter-node>, token :: <command-token>)
 => (value :: <object>);
  as(parameter-value-type(node), token-string(token));
end method;

/* Parameters have the successors of their command in addition to their own
 *
 * This is what allows having several parameters.
 */ 
define method node-successors (node :: <parameter-node>)
 => (successors :: <sequence>);
  if (parameter-command(node))
    concatenate(node-successors(parameter-command(node)), next-method());
  else
    next-method();
  end
end method;

/* Parameters match any token by default
 */
define method node-match (node :: <parameter-node>, parser :: <command-parser>, token :: <command-token>)
 => (matched? :: <boolean>);
  #t
end method;

/* Parameters complete only to themselves
 */
define method node-complete (node :: <parameter-node>, parser :: <command-parser>, token :: false-or(<command-token>))
 => (completions :: <command-completion>);
  make-completion(node, token,
                  exhaustive?: #f);
end method;

/* Parameters get registered as such when accepted
 */
define method node-accept (node :: <parameter-node>, parser :: <command-parser>, token :: <command-token>)
 => ();
  next-method();
  parser-push-parameter(parser, node, parameter-convert(parser, node, token));
end method;


/* Simple string parameter
 */
define class <string-parameter-node> (<parameter-node>)
end class;


/* Flag parameters
 */
define class <flag-node> (<parameter-node>, <symbol-node>)
end class;

define method parameter-convert (parser :: <command-parser>, node :: <flag-node>, token :: <command-token>)
 => (value :: <boolean>);
  #t;
end method;

define method node-match (node :: <flag-node>, parser :: <command-parser>, token :: <command-token>)
 => (matched? :: <boolean>);
  starts-with?(as(<string>, node-symbol(node)),
               as-lowercase(token-string(token)));
end method;

define method node-complete (node :: <flag-node>, parser :: <command-parser>, token :: false-or(<command-token>))
 => (completion :: <command-completion>);
  make-completion(node, token,
                  exhaustive?: #t,
                  complete-options: list(as(<string>, node-symbol(node))));
end method;

define method node-accept (node :: <flag-node>, parser :: <command-parser>, token :: <command-token>)
 => ();
  parser-push-parameter(parser, node, parameter-convert(parser, node, token));
end method;



/* One-of parameters
 *
 * Allows any of the given alternatives.
 */
define class <oneof-node> (<parameter-node>)
  slot oneof-case-sensitive? :: <boolean> = #f,
    init-keyword: case-sensitive?:;
  slot oneof-alternatives :: <list>,
    required-init-keyword: alternatives:;
end class;

define method node-match (node :: <oneof-node>, parser :: <command-parser>, token :: <command-token>)
 => (matched? :: <boolean>);
  let string = token-string(token);
  unless (oneof-case-sensitive?(node))
    string := as-lowercase(string);
  end;
  let alts = map(curry(as, <string>), oneof-alternatives(node));
  unless (oneof-case-sensitive?(node))
    alts := map(as-lowercase, alts);
  end;
  let found = choose(rcurry(starts-with?, string), alts);
  ~empty?(found);
end method;

define method node-complete (node :: <oneof-node>, parser :: <command-parser>, token :: false-or(<command-token>))
 => (completions :: <command-completion>);
  let case-sensitive? = node.oneof-case-sensitive?;
  let alternatives = map(curry(as, <string>), oneof-alternatives(node));
  unless (case-sensitive?)
    alternatives := map(as-lowercase, alternatives);
  end;
  make-completion(node, token,
                  exhaustive?: #t,
                  complete-options: alternatives);
end method;


/*
 * Parameter pointing to a file
 *
 * XXX This is still flawed in many ways.
 *     It works around locator limitations,
 *     doesn't deal well with symlinks
 *     and implements ~, . and .. using hacks.
 */
define class <file-node> (<parameter-node>)
  slot file-accept-directory? :: <boolean> = #f,
    init-keyword: accept-directory?:;
  slot file-accept-file? :: <boolean> = #t,
    init-keyword: accept-file?:;
  slot file-must-exist? :: <boolean> = #f,
    init-keyword: must-exist?:;
end class;

define method node-complete (node :: <file-node>, parser :: <command-parser>, token :: false-or(<command-token>))
 => (completion :: <command-completion>);

  // fixups to make locators treat magic things as directory locators
  //  XXX does not work for ~USER - locators not up to it?
  //  XXX this is crappy - locators are brain-dead in places
  let token-string =
    if (token)
      let s = token-string(token);
      case
        s = "." =>
          "./";
        s = ".." =>
          "../";
        starts-with?("~", s) & ~member?('/', s) =>
          concatenate(s, "/");
        otherwise =>
          s;
      end;
    else
      #f
    end;

  // locator of current token as hint
  let tloc =
    if (token-string)
      as(<file-locator>, token-string);
    else
      #f
    end;
  // directory to complete in
  let dir =
    if (tloc & locator-directory(tloc))
      locator-directory(tloc);
    else
      as(<directory-locator>, ".");
    end;

  // complete in that directory
  let completions = #();
  let children = directory-contents(dir);
  for (child in children)
    if (tloc)
      let tfn = locator-name(tloc);
      if (instance?(tloc, <directory-locator>))
        tfn := last(locator-path(tloc));
      end;
      if (instance?(child, <file-locator>))
        let cfn = locator-name(child);
        if ((tfn = "") | starts-with?(cfn, tfn))
          completions := add(completions, child);
        end;
      end;
      if (instance?(child, <directory-locator>))
        let cfn = last(locator-path(child));
        if ((tfn = "") | starts-with?(cfn, tfn))
          completions := add(completions, child);
        end;
      end;
    else
      completions := add(completions, child);
    end;
  end for;

  // filter out files if we don't want them
  // we don't do this for directories because they lead to files
  //if (~file-accept-file?(node))
  //completions := choose(complement(rcurry(instance?, <file-locator>)), completions);
  //end;

  let compl-strings = map(curry(as, <string>), completions);
  if (tloc)
    let tstr = as(<string>, tloc);
    if (~member?(tstr, compl-strings, test: \=))
      compl-strings := add(compl-strings, tstr);
    end
  end;

  local method as-option(string)
          make(<command-completion-option>,
               string: string);
        end;
  make(<command-completion>,
       node: node, token: token,
       exhaustive?: #f, options: map(as-option, compl-strings));
end method;

define method node-accept (node :: <file-node>, parser :: <command-parser>, token :: <command-token>)
 => ();
  next-method();
  let str = token-string(token);
  //if (file-must-exist?(node) & ~file-exists?(str))
  //  error("File does not exist");
  //end;
end method;
