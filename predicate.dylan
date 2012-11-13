module: cli

define function predicate-not(function)
 => (predicate :: <function>);
  method(#rest arguments)
   => (result :: <boolean>);
      ~apply(function, arguments);
  end method;
end function;

define function predicate-or(#rest functions)
 => (predicate :: <function>);
  method (#rest arguments)
   => (result :: <boolean>);
    let res :: <boolean> = #f;
    for(f in functions, until: res)
      res := apply(f, arguments);
    end for;
    res;
  end method;
end function;

define function predicate-and(#rest functions)
 => (predicate :: <function>);
  method (#rest arguments)
   => (result :: <boolean>);
    let res :: <boolean> = #f;
    for(f in functions, until: ~res)
      res := apply(f, arguments);
    end for;
    res;
  end method;
end function;
