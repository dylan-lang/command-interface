module: command-interface
synopsis: CLI phrase parser and completer.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

/* PARSE ERRORS */

define class <command-parse-error> (<simple-error>)
  slot error-parser :: <command-parser>,
    init-keyword: parser:;
  slot error-token :: <command-token>,
    init-keyword: token:;
end class;

define class <command-ambiguous-error> (<command-parse-error>)
end class;

define class <command-unknown-error> (<command-parse-error>)
end class;


/* PARSER */

define class <command-parser> (<object>)
  slot parser-source :: <command-source>,
    init-keyword: source:;

  slot parser-initial-node :: <command-node>,
    required-init-keyword: initial-node:;

  slot parser-current-node :: <command-node>;

  slot parser-tokens :: <list> = #();
  slot parser-nodes :: <list> = #();

  slot parser-commands :: <list> = #();
  slot parser-parameters :: <table> = make(<object-table>);
end class;

define method initialize (parser :: <command-parser>, #rest keys, #key, #all-keys)
 => ();
  next-method();
  parser-current-node(parser) := parser-initial-node(parser);
end method;

/* Verify the parsed command
 *
 */
define method parser-verify (parser :: <command-parser>)
 => ();
  let commands = parser-commands(parser);
  if (size(commands) > 0)
    let command :: <command-command> = last(commands);
    let expected-parameters = command-parameters(command);
    let provided-parameters = parser-parameters(parser).key-sequence;
    for (parameter in expected-parameters)
      if (parameter.parameter-required?)
        unless (member?(parameter-name(parameter), provided-parameters))
          error("Missing required parameter \"%s\"", as(<string>, parameter-name(parameter)));
        end;
      end;
    end;
  else
    error("Incomplete command");
  end; 
end method;

/* Execute the parsed command
 *
 * This will call the OUTERMOST handler.
 *
 * XXX we should expose a next-handler somehow
 *     so we can have wrapper commands like
 *     "with-log $logfile $command"
 */
define method parser-execute (parser :: <command-parser>)
 => ();
  let commands = parser-commands(parser);
  if (size(commands) > 0)
    let command :: <command-command> = last(commands);
    let function = command-handler(command);
    function(parser);
  else
    error("No command");
  end;
end method;

/* Parse the given token sequence
 *
 * Iterates over tokens and performs our regular phrase parse.
 * 
 */
define method parser-parse (parser :: <command-parser>, tokens :: <sequence>)
 => ();
  for (token in tokens)
    if (token-type(token) ~= #"whitespace")
      parser-advance(parser, token);
    end;
  end for;
end method;

define method parser-get-parameter (parser :: <command-parser>, name :: <symbol>, #key default :: <object> = #f)
 => (value :: <object>);
  element(parser-parameters(parser), name, default: default);
end method;

define method parser-push-parameter (parser :: <command-parser>, param :: <command-parameter>, value :: <object>)
 => (value :: <object>);
  if (node-repeatable?(param))
    element(parser-parameters(parser), parameter-name(param)) :=
      add(element(parser-parameters(parser), parameter-name(param), default: #()), value);
  else
    element(parser-parameters(parser), parameter-name(param)) := value;
  end;
  value;
end method;

define method parser-push-command (parser :: <command-parser>, h :: <command-command>)
 => ();
  parser-commands(parser) := add(parser-commands(parser), h);
end method;

define method parser-push-node (parser :: <command-parser>, token :: <command-token>, node :: <command-node>)
 => (node :: <command-node>);
  parser-current-node(parser) := node;
  parser-nodes(parser) := add(parser-nodes(parser), node);
  parser-tokens(parser) := add(parser-tokens(parser), token);
  node;
end method;

/* Advance the parser by one step
 */
define method parser-advance (parser :: <command-parser>, token :: <command-token>)
  let current-node = parser-current-node(parser);
  // filter out non-acceptable nodes
  let acceptable = choose(rcurry(node-acceptable?, parser),
                          node-successors(current-node));
  // find all matches
  let possible-matches = choose(rcurry(node-match, parser, token), acceptable);
  // get match priorities
  let possible-match-prios = map(node-priority, possible-matches);
  // find maximum priority
  let match-priority = reduce(max, $command-priority-minimum, possible-match-prios);
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
      signal(make(<command-unknown-error>,
                  format-string: "Unrecognized token \"%s\"",
                  format-arguments: vector(token-string(token)),
                  parser: parser,
                  token: token));
    // more than one: ambiguous token
    otherwise =>
      signal(make(<command-ambiguous-error>,
                  format-string: "Ambiguous token \"%s\"",
                  format-arguments: vector(token-string(token)),
                  parser: parser,
                  token: token));
  end select;
end method;

/* Perform completion on the current parser state
 */
define method parser-complete (parser :: <command-parser>, token :: false-or(<command-token>))
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
  // collect completions from each node and return them
  local method completion-for-node (node :: <command-node>)
         => (completion :: <command-completion>);
          node-complete(node, parser, token);
        end method;
  map(completion-for-node, acceptable);
end method;
