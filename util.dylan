module: cli

define function n-spaces(n :: <integer>)
  => (spaces :: <string>);
  let str = "";
  for(i from 0 below n)
    str := add(str, ' ');
  end;
  str;
end function;