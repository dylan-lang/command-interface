module: command-system
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
define abstract class <command-node> (<object>)
  /* possible (static) successors */
  slot node-successors :: <list> = #(),
    init-keyword: successors:;
  /* match and completion priority */
  slot node-priority :: <integer> = $command-priority-default,
    init-keyword: priority:;
  /* hidden nodes are not completed */
  slot node-hidden? :: <boolean> = #f,
    init-keyword: hidden?:;
  /* repeatable nodes may re-appear */
  slot node-repeatable? :: <boolean> = #f,
    init-keyword: repeatable?:;
  /* don't repeat if this node is already present */
  slot node-repeat-marker :: false-or(<command-node>) = #f,
    init-keyword: repeat-marker:;
end class;

/* Generate completions for the given node
 *
 * May or may not be provided a partial token.
 */
define open generic node-complete (node :: <command-node>, parser :: <command-parser>, token :: false-or(<command-token>))
 => (completions :: <list>);

/* Check if the given token matches this node partially or completely
 */
define open generic node-match (node :: <command-node>, parser :: <command-parser>, token :: <command-token>)
 => (matched? :: <boolean>);

/* Accept the given node with the given token as data
 *
 * This is where parameters do conversion and command handlers are added.
 */
define open generic node-accept ( node :: <command-node>, parser :: <command-parser>, token :: <command-token>)
 => ();


/* Is the node acceptable as next node in given parser state?
 *
 * This prevents non-repeatable parameters from being added again.
 *
 * Note how we also check for the repeat-marker of the node for
 * cases where another node can preclude our occurence.
 */
define method node-acceptable? (node :: <command-node>, parser :: <command-parser>)
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
define method node-add-successor (node :: <command-node>, successor :: <command-node>)
 => (successor :: <command-node>);
  node-successors(node) := add(node-successors(node), successor);
  successor;
end method;

/* Default matcher (always false)
 */
define method node-match (node :: <command-node>, parser :: <command-parser>, token :: <command-token>)
 => (matched? :: <boolean>);
  #f
end;

/* Default completer (no results)
 */
define method node-complete (node :: <command-node>, parser :: <command-parser>, token :: false-or(<command-token>))
 => (completions :: <list>);
  #();
end method;

/* Default acceptor (no-op)
 */
define method node-accept ( node :: <command-node>, parser :: <command-parser>, token :: <command-token>)
 => ();
end method;



/* Root of a command hierarchy.
 *
 * May not be completed or matched.
 */
define class <command-root> (<command-node>)
end class;

define method node-match (node :: <command-root>, parser :: <command-parser>, token :: <command-token>)
 => (matched? :: <boolean>);
  error("BUG: Tried to match a CLI root node");
end;

define method node-complete (node :: <command-root>, parser :: <command-parser>, token :: false-or(<command-token>))
 => (completions :: <list>);
  error("BUG: Tried to complete a CLI root node");
end method;


/* A fixed string
 *
 * Used to build commands and parameter prefixes.
 */
define class <command-symbol> (<command-node>)
  slot node-symbol :: <symbol>,
    init-keyword: name:;
end class;

define method node-match (node :: <command-symbol>, parser :: <command-parser>, token :: <command-token>)
 => (matched? :: <boolean>);
  starts-with?(as(<string>, node-symbol(node)),
               as-lowercase(token-string(token)));
end method;

define method node-complete (node :: <command-symbol>, parser :: <command-parser>, token :: false-or(<command-token>))
 => (completions :: <list>);
  if (~token | node-match(node, parser, token))
    list(as(<string>, node-symbol(node)))
  else
    #()
  end
end method;


/*
 * Commands are symbols with a handler and parameter requirements
 */
define open class <command-command> (<command-symbol>)
  /* help source for the command */
  slot command-help :: false-or(<string>) = #f,
    init-keyword: help:;
  /* handler function */
  slot command-handler :: false-or(<function>) = #f,
    init-keyword: handler:;
  /* parameters */
  slot command-parameters :: <list> = #();
end class;

define method node-accept (node :: <command-command>, parser :: <command-parser>, token :: <command-token>)
 => ();
  if (command-handler(node))
    parser-push-handler(parser, command-handler(node));
  end
end method;

define method command-add-parameter (node :: <command-command>, parameter :: <command-parameter>)
 => ();
  command-parameters(node) := add!(command-parameters(node), parameter);
end method;


/* Wrappers allow wrapping another command
 *
 * This is used for the "help" command so it can complete normal commands.
 *
 * They will have the successors of the given WRAPPER-ROOT.
 *
 */
define class <command-wrapper> (<command-command>)
  slot wrapper-root :: <command-node>,
    init-keyword: root:;
end class;

define method node-successors (node :: <command-wrapper>)
 => (successors :: <sequence>);
  concatenate(node-successors(wrapper-root(node)), next-method());
end method;


/* A captured parameter
 */
define open abstract class <command-parameter> (<command-node>)
  slot parameter-name :: <symbol>,
    init-keyword: name:;
  slot parameter-anchor :: false-or(<command-node>) = #f,
    init-keyword: anchor:;
  slot parameter-mandatory? :: <boolean> = #f,
    init-keyword: mandatory?:;
  slot parameter-value-type :: <type> = <string>,
    init-keyword: value-type:;
end class;

/* Parameters can be converted to values
 *
 * By default they convert to simple strings.
 */
define method parameter-convert (parser :: <command-parser>, node :: <command-parameter>, token :: <command-token>)
 => (value :: <object>);
  as(parameter-value-type(node), token-string(token));
end method;

/* Parameters have the successors of their anchor in addition to their own
 *
 * This is what allows having several parameters.
 */ 
define method node-successors (node :: <command-parameter>)
 => (successors :: <sequence>);
  if (parameter-anchor(node))
    concatenate(node-successors(parameter-anchor(node)), next-method());
  else
    next-method();
  end
end method;

/* Parameters match any token by default
 */
define method node-match (node :: <command-parameter>, parser :: <command-parser>, token :: <command-token>)
 => (matched? :: <boolean>);
  #t
end method;

/* Parameters complete only to themselves
 */
define method node-complete (node :: <command-parameter>, parser :: <command-parser>, token :: false-or(<command-token>))
 => (completions :: <list>);
  if (token)
    list(token-string(token));
  else
    #();
  end
end method;

/* Parameters get registered as such when accepted
 */
define method node-accept (node :: <command-parameter>, parser :: <command-parser>, token :: <command-token>)
 => ();
  next-method();
  parser-push-param(parser, node, parameter-convert(parser, node, token));
end method;


/* Simple string parameter
 */
define class <command-string> (<command-parameter>)
end class;


/* One-of parameters
 *
 * Allows any of the given alternatives.
 */
define class <command-oneof> (<command-parameter>)
  slot oneof-case-sensitive? :: <boolean> = #f,
    init-keyword: case-sensitive?:;
  slot oneof-alternatives :: <list>,
    required-init-keyword: alternatives:;
end class;

define method node-match (node :: <command-oneof>, parser :: <command-parser>, token :: <command-token>)
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

define method node-complete (node :: <command-oneof>, parser :: <command-parser>, token :: false-or(<command-token>))
 => (completions :: <list>);
  let alts = map(curry(as, <string>), oneof-alternatives(node));
  if (token)
    let string = token-string(token);
    unless (oneof-case-sensitive?(node))
      alts := map(as-lowercase, alts);
      string := as-lowercase(string);
    end;
    choose(rcurry(starts-with?, string), alts);
  else
    alts;
  end;
end method;


/*
 * Parameter pointing to a file
 *
 * XXX This is still flawed in many ways.
 *     It works around locator limitations,
 *     doesn't deal well with symlinks
 *     and implements ~, . and .. using hacks.
 */
define class <command-file> (<command-parameter>)
  slot file-accept-directory? :: <boolean> = #f,
    init-keyword: accept-directory?:;
  slot file-accept-file? :: <boolean> = #t,
    init-keyword: accept-file?:;
  slot file-must-exist? :: <boolean> = #f,
    init-keyword: must-exist?:;
end class;

define method node-complete (node :: <command-file>, parser :: <command-parser>, token :: false-or(<command-token>))
 => (completions :: <list>);
  let completions = #();

  // fixups to make locators treat magic things as directory locators
  //  XXX does not work for ~USER - locators not up to it?
  //  XXX this is crappy - locators are brain-dead in places
  let tstring =
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
    if (tstring)
      as(<file-locator>, tstring);
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
  let children = directory-contents(dir);
  for (child in children)
    let filename = locator-name(child);
    if (tloc)
      // accept files that match token hint
      let str = locator-name(tloc);
      // XXX this comparison probably breaks on windows
      if (filename = str | starts-with?(filename, str))
        completions := add(completions, child);
      end;
    else
      // accept all files
      completions := add(completions, child);
    end;
  end for;

  // filter out files if we don't want them
  // we don't do this for directories because they lead to files
  if (~file-accept-file?(node))
    completions := choose(complement(rcurry(instance?, <file-locator>)), completions);
  end;

  // if we have only one completion and it is
  // a directory, then if we are searching for files
  // (not just directories) we add an elipsis completion
  // so that shells don't think we are done
  if (size(completions) = 1
       & instance?(last(completions), <directory-locator>)
       & file-accept-file?(node))
    let elipsis = make(<file-locator>,
                       directory: last(completions),
                       name: "...");
    completions := add(completions, elipsis);
  end;

  map(curry(as, <string>), completions);
end method;

define method node-accept (node :: <command-file>, parser :: <command-parser>, token :: <command-token>)
 => ();
  next-method();
  let str = token-string(token);
  if (file-must-exist?(node) & ~file-exists?(str))
    error("File does not exist");
  end;
end method;
