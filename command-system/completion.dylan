module: command-system
synopsis: CLI completion.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define class <command-completion> (<object>)
  slot completion-node :: <command-node>,
    required-init-keyword: node:;
  slot completion-results :: <sequence>,
    required-init-keyword: results:;
end class;
