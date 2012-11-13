module: cli


/* TOKENS */

define class <cli-token> (<object>)
  slot token-string :: <string>,
    init-keyword: string:;
  slot token-srcloc :: <source-location>,
    init-keyword: srcloc:;
end class;


/* SOURCE RECORDS */

define abstract class <cli-source> (<source-record>)
end class;

define generic cli-tokenize(source :: <cli-source>)
 => (tokens :: <sequence>);

/* CLI source code provided as a string */
define class <cli-string-source> (<cli-source>)
  slot source-string :: <string>,
    init-keyword: string:;
end class;

define method cli-tokenize(source :: <cli-string-source>)
 => (tokens :: <sequence>);
  // XXX
  #();
end method;

/* CLI source code provided as a vector of strings */
define class <cli-vector-source> (<cli-source>)
  slot source-vector :: <sequence>,
    init-keyword: strings:;
end class;

define method cli-tokenize(source :: <cli-vector-source>)
 => (tokens :: <sequence>);
  let tokens :: <list> = #();
  let concat :: <string> = "";
  for(string in source-vector(source), posn from 0)
    if(posn > 0)
      concat := concatenate!(concat, " ");
    end;
    let token-start = size(concat);
    concat := concatenate!(concat, string);
    let token-end = size(concat) - 1;

    let srcloc =
      make-source-location
        (source,
         token-start, 0, token-start,
         token-end, 0, token-end);

    let token = make(<cli-token>,
                     string: string,
                     srcloc: srcloc);

    tokens := add(tokens, token);
  end for;
  reverse(tokens);
end method;

define method cli-annotate(stream :: <stream>, source :: <cli-vector-source>, srcloc :: <cli-srcloc>)
 => ();
  let tokens :: <sequence> = cli-tokenize(source);

  let code :: <string> = "  ";
  let marks :: <string> = "  ";

  for(token in tokens, posn from 0)
    if(posn > 0)
      code := concatenate!(code, " ");
      marks := concatenate!(marks, " ");
    end;

    let str = token-string(token);

    code := concatenate!(code, str);

    if(in-source-location?(srcloc, token-srcloc(token)))
      for(i from 0 below str.size)
        marks := concatenate!(marks, "^");
      end
    else
      for(i from 0 below str.size)
        marks := concatenate!(marks, " ");
      end
    end;
  end for;

  format(stream, "%s\n%s\n", code, marks);
end method;


/* SOURCE OFFSETS */

define class <cli-srcoff> (<big-source-offset>)
  slot source-offset-char :: <integer>,
    init-keyword: char:;
  slot source-offset-line :: <integer>,
    init-keyword: line:;
  slot source-offset-column :: <integer>,
    init-keyword: column:;
end class;

define method cli-srcoff(char, line, column)
  make(<cli-srcoff>, char: char, line: line, column: column);
end method;

define method source-offset-character-in
    (record :: <source-record>, offset :: <source-offset>) 
 => (pos :: <integer>);
  offset.source-offset-char;
end method;


/* SOURCE LOCATIONS */

define class <cli-srcloc> (<source-location>)
  slot source-location-source-record :: <cli-source>,
    init-keyword: source:;
  slot source-location-start-offset :: <cli-srcoff>,
    init-keyword: start:;
  slot source-location-end-offset :: <cli-srcoff>,
    init-keyword: end:;
end class;

define method make-source-location
    (source :: <cli-source>,
     start-char :: <integer>, start-line :: <integer>, start-col :: <integer>,
     end-char :: <integer>, end-line :: <integer>, end-col :: <integer>)
 => (loc :: <cli-srcloc>);
  make(<cli-srcloc>,
       source: source,
       start: cli-srcoff(start-char, start-line, start-col),
       end: cli-srcoff(end-char, end-line, end-col));
end method;

define method in-source-location?
    (srcloc :: <cli-srcloc>, other :: <cli-srcloc>)
 => (within? :: <boolean>);
  (other.source-location-start-character
     >= srcloc.source-location-start-character)
    & (other.source-location-end-character
         <= srcloc.source-location-end-character)
end method;

define method in-source-location?
    (srcloc :: <cli-srcloc>, other :: <cli-srcoff>)
 => (within? :: <boolean>);
  (other.source-offset-char
     >= srcloc.source-location-start-character)
    & (other.source-offset-char
         <= srcloc.source-location-end-character)
end method;
