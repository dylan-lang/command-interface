module: cli

define constant $cli-priority-minimum   = -10000;
define constant $cli-priority-parameter = -10;
define constant $cli-priority-default   =  0;


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
define abstract class <cli-node> (<object>)
  /* possible successors */
  slot node-successors :: <list> = #(),
    init-keyword: successors:;
  /* match and completion priority */
  slot node-priority :: <integer> = $cli-priority-default,
    init-keyword: priority:;
  /* hidden nodes are not completed */
  slot node-hidden? :: <boolean> = #f,
    init-keyword: hidden?:;
  /* repeatable nodes may re-appear */
  slot node-repeatable? :: <boolean> = #f,
    init-keyword: repeatable?:;
  /* don't repeat if this node is already present */
  slot node-repeat-marker :: false-or(<cli-node>) = #f,
    init-keyword: repeat-marker:;
end class;

/* Is the node acceptable as next node in given parser state?
 *
 * This prevents non-repeatable parameters from being added again.
 *
 * Note how we also check for the repeat-marker of the node for
 * cases where another node can preclude our occurence.
 */
define method node-acceptable? (node :: <cli-node>, parser :: <cli-parser>)
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
define method node-add-successor (node :: <cli-node>, successor :: <cli-node>)
 => (successor :: <cli-node>);
  node-successors(node) := add(node-successors(node), successor);
  successor;
end method;

/* Check if the given token matches this node partially or completely
 */
define method node-match (node :: <cli-node>, parser :: <cli-parser>, token :: <cli-token>)
 => (matched? :: <boolean>);
  #f
end;

/* Generate completions for the given node
 *
 * May or may not be provided a partial token.
 */
define method node-complete (node :: <cli-node>, parser :: <cli-parser>, token :: false-or(<cli-token>))
 => (completions :: <list>);
  #();
end method;

/* Accept the given node with the given token as data
 *
 * This is where parameters do conversion and command handlers are added.
 */
define method node-accept ( node :: <cli-node>, parser :: <cli-parser>, token :: <cli-token>)
 => ();
end method;



/* Root of a command hierarchy.
 *
 * May not be completed or matched.
 */
define class <cli-root> (<cli-node>)
end class;


/* A fixed string
 *
 * Used to build commands and parameter prefixes.
 */
define class <cli-symbol> (<cli-node>)
  slot node-symbol :: <symbol>,
    init-keyword: name:;
end class;

define method node-match (node :: <cli-symbol>, parser :: <cli-parser>, token :: <cli-token>)
 => (matched? :: <boolean>);
  starts-with?(as(<string>, node-symbol(node)),
               as-lowercase(token-string(token)));
end method;

define method node-complete (node :: <cli-symbol>, parser :: <cli-parser>, token :: false-or(<cli-token>))
 => (completions :: <list>);
  if (~token | node-match(node, parser, token))
    list(as(<string>, node-symbol(node)))
  else
    #()
  end
end method;


/*
 * Commands are symbols with handler and parameter requirements
 */
define class <cli-command> (<cli-symbol>)
  /* help source for the command */
  slot command-help :: false-or(<string>) = #f,
    init-keyword: help:;
  /* handler function */
  slot command-handler :: false-or(<function>) = #f,
    init-keyword: handler:;
end class;

define method node-accept (node :: <cli-command>, parser :: <cli-parser>, token :: <cli-token>)
 => ()
  if (command-handler(node))
    parser-push-handler(parser, command-handler(node));
  end
end method;


/* Wrappers allow wrapping another command
 *
 * This is used for the "help" command so it can complete normal commands.
 *
 * They will have the successors of the given WRAPPER-ROOT.
 *
 */
define class <cli-wrapper> (<cli-command>)
  slot wrapper-root :: <cli-node>,
    init-keyword: root:;
end class;

define method node-successors (node :: <cli-wrapper>)
 => (successors :: <sequence>);
  concatenate(node-successors(wrapper-root(node)), next-method());
end method;


/*
 * A captured parameter
 */
define class <cli-parameter> (<cli-node>)
  slot parameter-name :: <symbol>,
    init-keyword: name:;
  slot parameter-anchor :: false-or(<cli-node>) = #f,
    init-keyword: anchor:;
  slot parameter-mandatory? :: <boolean> = #f,
    init-keyword: mandatory?:;
end class;

define method node-successors (node :: <cli-parameter>)
 => (successors :: <sequence>);
  if (parameter-anchor(node))
    concatenate(node-successors(parameter-anchor(node)), next-method());
  else
    next-method();
  end
end method;

define method node-match (node :: <cli-parameter>, parser :: <cli-parser>, token :: <cli-token>)
 => (matched? :: <boolean>);
  #t
end method;

define method node-complete (node :: <cli-parameter>, parser :: <cli-parser>, token :: false-or(<cli-token>))
 => (completions :: <list>);
  if (token)
    list(token-string(token));
  else
    #();
  end
end method;

define method node-accept (node :: <cli-parameter>, parser :: <cli-parser>, token :: <cli-token>)
 => ();
  next-method();
  parser-push-param(parser, node, parameter-convert(parser, node, token));
end method;

define method parameter-convert (parser :: <cli-parser>, node :: <cli-parameter>, token :: <cli-token>)
 => (value :: <object>);
  token-string(token);
end method;


/*
 * Simple string parameter
 */
define class <cli-string> (<cli-parameter>)
end class;


/*
 * Parameter pointing to a file
 */
define class <cli-file> (<cli-parameter>)
  slot file-accept-directory? :: <boolean> = #f,
    init-keyword: accept-directory?:;
  slot file-accept-file? :: <boolean> = #t,
    init-keyword: accept-file?:;
  slot file-must-exist? :: <boolean> = #f,
    init-keyword: must-exist?:;
end class;

define method node-complete (node :: <cli-file>, parser :: <cli-parser>, token :: false-or(<cli-token>))
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
    completions := choose(rcurry(instance?, <file-locator>), completions);
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

define method node-accept (node :: <cli-file>, parser :: <cli-parser>, token :: <cli-token>)
 => ();
  next-method();
  let str = token-string(token);
  if (~file-exists?(str))
    error("File does not exist");
  end;
end method;


define class <cli-oneof> (<cli-parameter>)
  slot node-alternatives :: <list>,
    init-keyword: alternatives:;
end class;

define method node-match (node :: <cli-oneof>, parser :: <cli-parser>, token :: <cli-token>)
 => (matched? :: <boolean>);
  // try matching all alternatives
  let found = choose(rcurry(node-match, parser, token), node-alternatives(node));
  // if any match then we do, too
  size(found) > 0;
end method;

define method node-complete (node :: <cli-oneof>, parser :: <cli-parser>, token :: false-or(<cli-token>))
 => (completions :: <list>);
  // find all alternatives that can accept TOKEN
  let found =
    if (token)
      choose(rcurry(node-match, parser, token), node-alternatives(node));
    else
      node-alternatives(node);
    end;
  // produce completions for all possible
  // alternatives and collect them into one list
  apply(concatenate,
        map(rcurry(node-complete, parser, token), found));
end method;

