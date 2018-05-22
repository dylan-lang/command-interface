module: command-interface
synopsis: Utility functions.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define function and (a :: <boolean>, b :: <boolean>)
 => (r :: <boolean>);
  a & b;
end;

define function or (a :: <boolean>, b :: <boolean>)
 => (r :: <boolean>);
  a | b;
end;

define constant n-spaces = curry(pad, "");

define function longest-common-prefix (strings :: <sequence>)
 => (prefix :: <string>);
  block (return)
    if(empty?(strings))
      ""
    else
      for (i from 0)
        let first = first(strings);
        for (string in strings)
          if (i == size(string) | string[i] ~= first[i])
            return(copy-sequence(first, end: i));
          end;
        end;
      end;
    end;
  end
end function;
