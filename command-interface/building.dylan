module: command-interface
synopsis: Utilities for constructing CLI node structures.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define method build-command (root :: <root-node>, name :: <sequence>,
                             #rest node-keys,
                             #key node-class :: <class> = <command-node>, #all-keys)
 => (cmd :: <symbol-node>);
  local
    method find-or-make-successor (node :: <parse-node>,
                                   symbol :: <symbol>,
                                   node-class :: <class>,
                                   node-keys :: <sequence>)
      // find symbol in existing successors
      let found = #f;
      for (s in node-successors(node), until: found)
        if (instance?(s, <symbol-node>) & (node-symbol(s) == symbol))
          found := s;
        end if;
      end for;
      // if not found then make one
      if (~found)
        found := apply(make, node-class, symbol:, symbol, node-keys);
        node-add-successor(node, found);
      end if;
      // return whatever we have now
      found;
    end;
  // find or create symbol nodes for entire name sequence
  let cur = root;
  for (n in name, i from 0)
    // determine what to instantiate, if needed
    let (cls, keys) =
      if (i == size(name) - 1)
        values(node-class, node-keys);
      else
        values(<symbol-node>, #[]);
      end;
    // find or make the node
    cur := find-or-make-successor
      (cur, as(<symbol>, n), cls, keys);
  end for;
  // return the last symbol in the chain
  cur;
end method;

define method build-command (root :: <root-node>, name :: <string>,
                             #rest keys, #key, #all-keys)
 => (cmd :: <command-node>);
  apply(build-command, root, list(name), keys);
end method;

define method build-command (root :: <root-node>, name :: <symbol>,
                             #rest keys, #key, #all-keys)
 => (cmd :: <command-node>);
  apply(build-command, root, list(name), keys);
end method;


define function build-parameter (command :: <command-node>, name :: <symbol>,
                                 #rest keys,
                                 #key syntax :: <symbol> = #"named",
                                 #all-keys)
 => (entry :: <parse-node>);
  select (syntax)
    #"flag" => apply(build-flag-parameter, command, name, keys);
    #"named" => apply(build-named-parameter, command, name, keys);
    #"simple" => apply(build-simple-parameter, command, name, keys);
    otherwise => error("Invalid parameter syntax %=", syntax);
  end;
end;

define function build-flag-parameter (command :: <command-node>, name :: <symbol>,
                                      #rest keys, #key node-class :: <class> = <flag-node>, #all-keys)
  => (param :: <flag-node>);
  let param = apply(make, node-class,
                    name:, name,
                    symbol:, name,
                    kind:, #"flag",
                    command: command,
                    priority: $command-priority-default,
                    keys);
  node-add-successor(command, param);
  command-add-parameter(command, param);
  param;
end function;

define function build-simple-parameter (command :: <command-node>, name :: <symbol>,
                                        #rest keys, #key node-class :: <class> = <string-parameter-node>, #all-keys)
 => (entry :: <parse-node>);
  let param = apply(make, node-class,
                    name:, name,
                    kind:, #"simple",
                    command:, command,
                    priority:, $command-priority-parameter,
                    keys);
  node-add-successor(command, param);
  command-add-parameter(command, param);
  param;
end function;

define method build-named-parameter (command :: <command-node>, names :: <sequence>,
                                     #rest keys, #key node-class :: <class> = <string-parameter-node>, #all-keys)
 => (param :: <parameter-node>, symbols :: <sequence>);
  let param = apply(make, node-class,
                    name:, element(names, 0),
                    kind:, #"named",
                    command:, command,
                    priority:, $command-priority-parameter,
                    keys);
  let syms = #();
  for (name in names)
    let sym = make(<parameter-symbol-node>,
                   symbol: as(<symbol>, name),
                   parameter: param,
                   repeatable?: node-repeatable?(param),
                   repeat-marker: param,
                   successors: list(param));
    syms := add(syms, sym);
    node-add-successor(command, sym);
  end for;
  command-add-parameter(command, param);
  values(param, syms);
end method;

define method build-named-parameter (command :: <command-node>, name :: <symbol>,
                                     #rest keys, #key, #all-keys)
 => (param :: <parameter-node>, symbols :: <sequence>);
  apply(build-named-parameter, command, list(name), keys);
end method;
