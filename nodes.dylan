module: cli

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
define method node-acceptable?(node :: <cli-node>, parser :: <cli-parser>)
 => (acceptable? :: <boolean>);
  if(node-repeatable?(node))
    #t
  else
    ~member?(node, parser-nodes(parser))
      & (node-repeat-marker(node) == #f
           | ~member?(node-repeat-marker(node), parser-nodes(parser)));
  end
end method;

/* Add a possible successor node
 */
define method node-add-successor(node :: <cli-node>, successor :: <cli-node>)
 => (successor :: <cli-node>);
  node-successors(node) := add(node-successors(node), successor);
  successor;
end method;

/* Check if the given token matches this node partially or completely
 */
define method node-match(parser :: <cli-parser>, node :: <cli-node>, token :: <cli-token>)
 => (matched? :: <boolean>);
  #f
end;

/* Generate completions for the given node
 *
 * May or may not be provided a partial token.
 */
define method node-complete(parser :: <cli-parser>, node :: <cli-node>, token :: false-or(<cli-token>))
 => (completions :: <list>);
  #();
end method;

/* Accept the given node with the given token as data
 *
 * This is where parameters do conversion and command handlers are added.
 */
define method node-accept(parser :: <cli-parser>, node :: <cli-node>, token :: <cli-token>)
 => ();
end method;



/* Root of a command hierarchy.
 *
 * May not be completed or matched.
 */
define class <cli-root> (<cli-node>)
end class;

define method root-define-command(root :: <cli-root>, name :: <sequence>,
                                  #rest node-keys,
                                  #key node-class :: <class> = <cli-command>, #all-keys)
 => (cmd :: <cli-symbol>);
  local
    method find-or-make-successor(node :: <cli-node>,
                                  symbol :: <symbol>,
                                  node-class :: <class>,
                                  node-keys :: <sequence>)
      // find symbol in existing successors
      let found = #f;
      for(s in node-successors(node), until: found)
        if(instance?(s, <cli-symbol>) & (node-symbol(s) == symbol))
          found := s;
        end if;
      end for;
      // if not found then make one
      if(~found)
        found := apply(make, node-class, name:, symbol, node-keys);
        node-add-successor(node, found);
      end if;
      // return whatever we have now
      found;
    end;
  // find or create symbol nodes for entire name sequence
  let cur = root;
  for(n in name, i from 0)
    // determine what to instantiate, if needed
    let (cls, keys) =
      if(i == size(name) - 1)
        values(node-class, node-keys);
      else
        values(<cli-symbol>, #[]);
      end;
    // find or make the node
    cur := find-or-make-successor
      (cur, as(<symbol>, n), cls, keys);
  end for;
  // return the last symbol in the chain
  cur;
end method;

define method root-define-command(root :: <cli-root>, name :: <string>,
                                  #rest keys, #key, #all-keys)
 => (cmd :: <cli-symbol>);
  apply(root-define-command, root, list(name), keys);
end method;

define method root-define-command(root :: <cli-root>, name :: <symbol>,
                                  #rest keys, #key, #all-keys)
 => (cmd :: <cli-symbol>);
  apply(root-define-command, root, list(name), keys);
end method;



/* A fixed string
 *
 * Used to build commands and parameter prefixes.
 */
define class <cli-symbol> (<cli-node>)
  slot node-symbol :: <symbol>,
    init-keyword: name:;
end class;

define method node-match(parser :: <cli-parser>, node :: <cli-symbol>, token :: <cli-token>)
 => (matched? :: <boolean>);
  starts-with?(as(<string>, node-symbol(node)),
               as-lowercase(token-string(token)));
end method;

define method node-complete(parser :: <cli-parser>, node :: <cli-symbol>, token :: false-or(<cli-token>))
 => (completions :: <list>);
  if(~token | node-match(parser, node, token))
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

define method node-accept(parser :: <cli-parser>, node :: <cli-command>, token :: <cli-token>)
 => ()
  if(command-handler(node))
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

define method node-successors(node :: <cli-wrapper>)
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

define method node-successors(node :: <cli-parameter>)
 => (successors :: <sequence>);
  if(parameter-anchor(node))
    concatenate(node-successors(parameter-anchor(node)), next-method());
  else
    next-method();
  end
end method;

define method node-match(parser :: <cli-parser>, node :: <cli-parameter>, token :: <cli-token>)
 => (matched? :: <boolean>);
  #t
end method;

define method node-complete(parser :: <cli-parser>, node :: <cli-parameter>, token :: <cli-token>)
 => (completions :: <list>);
  list(token-string(token));
end method;

define method node-accept(parser :: <cli-parser>, node :: <cli-parameter>, token :: <cli-token>)
 => ();
  next-method();
  parser-push-param(parser, node, parameter-convert(parser, node, token));
end method;

define method parameter-convert(parser :: <cli-parser>, node :: <cli-parameter>, token :: <cli-token>)
 => (value :: <object>);
  token-string(token);
end method;

define function make-simple-param(anchor :: <cli-node>, name :: <symbol>, #rest keys, #key, #all-keys)
 => (entry :: <cli-node>);
  let param = apply(make, <cli-parameter>,
                    name:, name,
                    anchor:, anchor,
                    keys);
  node-add-successor(anchor, param);
  param;
end function;

define method make-named-param(anchor :: <cli-node>, names :: <sequence>, #rest keys, #key, #all-keys)
 => (param :: <cli-node>, symbols :: <sequence>);
  let param = apply(make, <cli-parameter>,
                    name:, element(names, 0),
                    anchor:, anchor,
                    keys);
  let syms = #();
  for(name in names)
    let sym = make(<cli-symbol>,
                   name: as(<symbol>, name),
                   repeatable?: node-repeatable?(param),
                   repeat-marker: param,
                   successors: list(param));
    syms := add(syms, sym);
    node-add-successor(anchor, sym);
  end for;
  values(param, syms);
end method;

define method make-named-param(anchor :: <cli-node>, name :: <symbol>, #rest keys, #key, #all-keys)
 => (param :: <cli-parameter>, symbol :: <cli-symbol>);
  let (param, syms) = apply(make-named-param, anchor, list(name), keys);
  values(param, element(syms, 0));
end method;


define class <cli-string> (<cli-parameter>)
end class;


define class <cli-file> (<cli-parameter>)
  slot file-must-exist? :: <boolean> = #t,
    init-keyword: must-exist?:;
end class;

define method node-match(parser :: <cli-parser>, node :: <cli-file>, token :: <cli-token>)
 => (matched? :: <boolean>);
  #t
end method;

define method node-accept(parser :: <cli-parser>, node :: <cli-file>, token :: <cli-token>)
 => ();
  next-method();
  let str = token-string(token);
  if(~file-exists?(str))
    error("File does not exist");
  end;
end method;


define class <cli-oneof> (<cli-parameter>)
  slot node-alternatives :: <list>,
    init-keyword: alternatives:;
end class;

define method node-match(parser :: <cli-parser>, node :: <cli-oneof>, token :: <cli-token>)
 => (matched? :: <boolean>);
  // try matching all alternatives
  let found = choose(parser-node-matcher(parser, token), node-alternatives(node));
  // if any match then we do, too
  size(found) > 0;
end method;

define method node-complete(parser :: <cli-parser>, node :: <cli-oneof>, token :: <cli-token>)
 => (completions :: <list>);
  // find all alternatives that can accept TOKEN
  let found = choose(parser-node-matcher(parser, token), node-alternatives(node));
  // produce completions for all possible
  // alternatives and collect them into one list
  apply(concatenate,
        map(parser-node-completer(parser, token), found));
end method;

