module: cli
synopsis: CLI phrase parser and completer.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

/* PARSE ERRORS */

define class <cli-parse-error> (<simple-error>)
  slot error-parser :: <cli-parser>,
    init-keyword: parser:;
  slot error-token :: <cli-token>,
    init-keyword: token:;
end class;

define class <cli-ambiguous-error> (<cli-parse-error>)
end class;

define class <cli-unknown-error> (<cli-parse-error>)
end class;


/* PARSER */

define class <cli-parser> (<object>)
  slot parser-source :: <cli-source>,
    init-keyword: source:;

  slot parser-initial-node :: <cli-node>,
    required-init-keyword: initial-node:;

  slot parser-current-node :: <cli-node>;

  slot parser-handlers :: <list> = #();

  slot parser-tokens :: <list> = #();
  slot parser-nodes :: <list> = #();

  slot parser-parameters :: <table> = make(<object-table>);
end class;

define method initialize (parser :: <cli-parser>, #rest keys, #key, #all-keys)
 => ();
  next-method();
  parser-current-node(parser) := parser-initial-node(parser);
end method;

/* Execute the parsed command
 *
 * This will call the OUTERMOST handler.
 *
 * XXX we should expose a next-handler somehow
 *     so we can have wrapper commands like
 *     "with-log $logfile $command"
 */
define method parser-execute (parser :: <cli-parser>)
 => ();
  let handlers = reverse(parser-handlers(parser));
  if (size(handlers) > 0)
    let hn = element(handlers, 0);
    hn(parser);
  end;
end method;

/* Parse the given token sequence
 *
 * Iterates over tokens and performs our regular phrase parse.
 * 
 */
define method parser-parse (parser :: <cli-parser>, tokens :: <sequence>)
 => ();
  for (token in tokens)
    if (token-type(token) ~= #"whitespace")
      parser-advance(parser, token);
    end;
  end for;
end method;

define method parser-get-parameter (parser :: <cli-parser>, name :: <symbol>, #key default :: <object> = #f)
 => (value :: <object>);
  element(parser-parameters(parser), name, default: default);
end method;

define method parser-push-param (parser :: <cli-parser>, param :: <cli-parameter>, value :: <object>)
 => (value :: <object>);
  if (node-repeatable?(param))
    element(parser-parameters(parser), parameter-name(param)) :=
      add(element(parser-parameters(parser), parameter-name(param), default: #()), value);
  else
    element(parser-parameters(parser), parameter-name(param)) := value;
  end;
  value;
end method;

define method parser-push-handler (parser :: <cli-parser>, h :: <function>)
 => ();
  parser-handlers(parser) := add(parser-handlers(parser), h);
end method;

define method parser-push-node (parser :: <cli-parser>, token :: <cli-token>, node :: <cli-node>)
 => (node :: <cli-node>);
  parser-current-node(parser) := node;
  parser-nodes(parser) := add(parser-nodes(parser), node);
  parser-tokens(parser) := add(parser-tokens(parser), token);
  node;
end method;

/* Advance the parser by one step
 */
define method parser-advance (parser :: <cli-parser>, token :: <cli-token>)
  let current-node = parser-current-node(parser);
  // filter out non-acceptable nodes
  let acceptable = choose(rcurry(node-acceptable?, parser),
                          node-successors(current-node));
  // find all matches
  let possible-matches = choose(rcurry(node-match, parser, token), acceptable);
  // get match priorities
  let possible-match-prios = map(node-priority, possible-matches);
  // find maximum priority
  let match-priority = reduce(max, $cli-priority-minimum, possible-match-prios);
  // filter by priority
  let matches = choose-by(curry(\==, match-priority), possible-match-prios, possible-matches);
  // act on matches
  select (matches.size)
    // exactly one match: we found a match
    1 =>
      begin
        let succ = element(matches, 0);
        node-accept(succ, parser, token);
        parser-push-node(parser, token, succ);
      end;
    // no match: unknown token
    0 =>
      signal(make(<cli-unknown-error>,
                  format-string: "Unrecognized token \"%s\"",
                  format-arguments: vector(token-string(token)),
                  parser: parser,
                  token: token));
    // more than one: ambiguous token
    otherwise =>
      signal(make(<cli-ambiguous-error>,
                  format-string: "Ambiguous token \"%s\"",
                  format-arguments: vector(token-string(token)),
                  parser: parser,
                  token: token));
  end select;
end method;

/* Perform completion on the current parser state
 */
define method parser-complete (parser :: <cli-parser>, token :: false-or(<cli-token>))
 => (completions :: <sequence>);
  let current-node = parser-current-node(parser);
  // get all non-hidden successors
  let acceptable = choose(complement(node-hidden?), node-successors(current-node));
  // filter out non-acceptable nodes
  acceptable := choose(rcurry(node-acceptable?, parser), acceptable);
  // filter with token if available
  if (token)
    acceptable := choose(rcurry(node-match, parser, token), acceptable);
  end;
  // collect completions from each node
  local method completion-for-node (node :: <cli-node>)
         => (completion :: <cli-completion>);
          make(<cli-completion>,
               node: node,
               results: node-complete(node, parser, token));
        end method;
  let completions = map(completion-for-node, acceptable);
  // return
  completions;
end method;
