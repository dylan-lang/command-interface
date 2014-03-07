module: cli
synopsis: CLI completion.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define class <cli-completion> (<object>)
  slot completion-node :: <cli-node>,
    required-init-keyword: node:;
  slot completion-results :: <sequence>,
    required-init-keyword: results:;
end class;
