module: cli

define function n-spaces (n :: <integer>)
  => (spaces :: <string>);
  let str = "";
  for (i from 0 below n)
    str := add(str, ' ');
  end;
  str;
end function;

define function longest-common-prefix (strings :: <sequence>)
 => (prefix :: <string>);
  block (return)
    for (i from 0)
      let first = first(strings);
      for (string in strings)
        if (i == size(string) | string[i] ~= first[i])
          return(copy-sequence(first, end: i));
        end;
      end;
    end;
  end;
end function;
