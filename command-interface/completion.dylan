module: command-interface
synopsis: CLI completion.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

/**
 * Represents the result of completing a node,
 * possibly hinted by a pre-existing token.
 */
define class <command-completion> (<object>)
  /* node the completion was performed for */
  slot completion-node :: <command-node>,
    required-init-keyword: node:;
  /* token used to hint the completion, if provided */
  slot completion-token :: false-or(<command-token>) = #f,
    init-keyword: token:;
  /* was this completion exhaustive? (if yes then only given options are valid) */
  slot completion-exhaustive? :: <boolean> = #f,
    init-keyword: exhaustive?:;
  /* actual completion options */
  slot completion-options :: <list> = #(),
    init-keyword: options:;
end class;

define method initialize (completion :: <command-completion>,
                          #rest args, #key, #all-keys)
 => ();
  next-method();
  for (option in completion.completion-options)
    option-completion(option) := completion;
  end;
end method;

/**
 * Represents a single option returned by completion
 *
 * An option may be COMPLETE.
 * This means that we would accept it in execution.
 */
define class <command-completion-option> (<object>)
  slot option-completion :: false-or(<command-completion>) = #f;
  /* string for this option */
  slot option-string :: <string>,
    required-init-keyword: string:;
  /* true if this option is complete */
  slot option-complete? :: <boolean> = #f,
    init-keyword: complete?:;
end class;

define function make-exhaustive-completion (node :: <command-node>,
                                            token :: false-or(<command-token>),
                                            #key complete-options :: <list> = #(),
                                                 other-options :: <list> = #())
  => (completion :: <command-completion>);
  local method as-complete-option(string :: <string>)
          make(<command-completion-option>, string: string, complete?: #t);
        end,
        method as-other-option(string :: <string>)
          make(<command-completion-option>, string: string);
        end;
  make(<command-completion>,
       node: node, token: token,
       exhaustive?: #t,
       options: concatenate(map(as-complete-option, complete-options),
                            map(as-other-option, other-options)));
end;
