module: command-interface
synopsis: Utilities for constructing CLI node structures.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define method build-command (root :: <command-root>, name :: <sequence>,
                             #rest node-keys,
                             #key node-class :: <class> = <command-command>, #all-keys)
 => (cmd :: <command-symbol>);
  local
    method find-or-make-successor (node :: <command-node>,
                                   symbol :: <symbol>,
                                   node-class :: <class>,
                                   node-keys :: <sequence>)
      // find symbol in existing successors
      let found = #f;
      for (s in node-successors(node), until: found)
        if (instance?(s, <command-symbol>) & (node-symbol(s) == symbol))
          found := s;
        end if;
      end for;
      // if not found then make one
      if (~found)
        found := apply(make, node-class, name:, symbol, node-keys);
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
        values(<command-symbol>, #[]);
      end;
    // find or make the node
    cur := find-or-make-successor
      (cur, as(<symbol>, n), cls, keys);
  end for;
  // return the last symbol in the chain
  cur;
end method;

define method build-command (root :: <command-root>, name :: <string>,
                             #rest keys, #key, #all-keys)
 => (cmd :: <command-symbol>);
  apply(build-command, root, list(name), keys);
end method;

define method build-command (root :: <command-root>, name :: <symbol>,
                             #rest keys, #key, #all-keys)
 => (cmd :: <command-symbol>);
  apply(build-command, root, list(name), keys);
end method;


define function build-parameter (command :: <command-command>, name :: <symbol>,
                                 #rest keys,
                                 #key syntax :: <symbol> = #"named",
                                      node-class :: <class> = <command-string>,
                                 #all-keys)
 => (entry :: <command-node>);
  select (syntax)
      #"named" => apply(build-named-parameter, command, name, keys);
      #"simple" => apply(build-simple-parameter, command, name, keys);
      #"inline" => apply(build-inline-parameter, command, name, keys);
      otherwise => error("Invalid parameter syntax %=", syntax);
  end;
end;

define function build-simple-parameter (command :: <command-command>, name :: <symbol>,
                                        #rest keys, #key node-class :: <class> = <command-string>, #all-keys)
 => (entry :: <command-node>);
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

define method build-named-parameter (command :: <command-command>, names :: <sequence>,
                                     #rest keys, #key node-class :: <class> = <command-string>, #all-keys)
 => (param :: <command-node>, symbols :: <sequence>);
  let param = apply(make, node-class,
                    name:, element(names, 0),
                    kind:, #"named",
                    command:, command,
                    priority:, $command-priority-parameter,
                    keys);
  let syms = #();
  for (name in names)
    let sym = make(<command-symbol>,
                   name: as(<symbol>, name),
                   repeatable?: node-repeatable?(param),
                   repeat-marker: param,
                   successors: list(param));
    syms := add(syms, sym);
    node-add-successor(command, sym);
  end for;
  command-add-parameter(command, param);
  values(param, syms);
end method;

define method build-named-parameter (command :: <command-command>, name :: <symbol>,
                                     #rest keys, #key, #all-keys)
 => (param :: <command-parameter>, symbols :: <sequence>);
  apply(build-named-parameter, command, list(name), keys);
end method;

define method build-inline-parameter (command :: <command-command>, names,
                                      #rest keys, #key, #all-keys)
 => (param :: <command-node>, symbols :: <sequence>);
  let (param, syms) = apply(build-named-parameter, command, names, keys);

  node-add-successor(command, param);

  values(param, syms);
end method;
