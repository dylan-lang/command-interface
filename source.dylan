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

define generic source-string(source :: <cli-source>)
 => (whole-source :: <string>);


/* CLI source code provided as a string */
define class <cli-string-source> (<cli-source>)
  slot source-string :: <string>,
    init-keyword: string:;
end class;

define class <cli-lexer-error> (<simple-error>)
  slot error-source :: <cli-source>,
    init-keyword: source:;
  slot error-string :: <string>,
    init-keyword: string:;
  slot error-srcoff :: <cli-srcoff>,
    init-keyword: srcoff:;
end class;

define method cli-tokenize(source :: <cli-string-source>)
 => (tokens :: <sequence>);
  let string = source-string(source);
  let tokens = #();
  let state = #"initial";

  let collected-start = #f;
  let collected-end = #f;
  let collected-chars = #();

  local
    method push-simple(char :: <character>, offset :: <integer>)
     => ();
      let srcloc = make-source-location(source,
                                        offset, 0, offset,
                                        offset, 0, offset);
      let token = make(<cli-token>,
                       string: as(<string>, vector(char)),
                       srcloc: srcloc);
      tokens := add(tokens, token);
    end,
    method collect-char(char :: <character>, offset :: <integer>)
     => ();
      unless(collected-start)
        collected-start := offset;
      end;
      collected-end := offset;
      collected-chars := add(collected-chars, char);
    end,
    method maybe-push-collected()
     => ();
      if(collected-start)
        let str = as(<string>, reverse(collected-chars));
        let srcloc = make-source-location(source,
                                          collected-start, 0, collected-start,
                                          collected-end, 0, collected-end);

        let token = make(<cli-token>,
                         string: str,
                         srcloc: srcloc);
        tokens := add(tokens, token);

        collected-chars := #();
        collected-start := #f;
        collected-end := #f;
      end;
    end,
    method invalid(char, offset, message)
      => ();
      signal(make(<cli-lexer-error>,
                  format-string: "Lexical error: %s",
                  format-arguments: vector(message),
                  source: source,
                  string: string,
                  srcoff: cli-srcoff(offset, 0, offset)));
    end method;

  for(char in string, offset from 0)
    select(state)
      #"initial" =>
        case
          char.whitespace? =>
            maybe-push-collected();
          char = '"' =>
            state := #"dquote";
          char = '?' =>
            if(collected-start)
              collect-char(char, offset);
            else
              push-simple(char, offset);
            end;
          char.graphic? =>
            collect-char(char, offset);
          otherwise =>
            invalid(char, offset, "character not allowed here");
        end;
      #"dquote" =>
        select(char)
          '"' =>
            state := #"initial";
          '\\' =>
            state := #"dquote-backslash";
          otherwise =>
            collect-char(char, offset);
        end;
      #"dquote-backslash" =>
        select(char)
          '\\', '"' =>
            begin
              collect-char(char, offset);
              state := #"dquote";
            end;
          otherwise =>
            invalid(char, offset, "character not allowed here");
        end;
    end;
  end for;

  if(state == #"initial")
    maybe-push-collected();
  else
    invalid(' ', size(string), "incomplete token");
  end;

  reverse(tokens);
end method;

/* CLI source code provided as a vector of strings */
define class <cli-vector-source> (<cli-source>)
  slot source-vector :: <sequence>,
    init-keyword: strings:;
end class;

define method source-string(source :: <cli-vector-source>)
 => (string :: <string>);
  join(source-vector(source), " ");
end method;

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

define method cli-annotate(source :: <cli-source>, srcoff :: <cli-srcoff>)
 => (marks :: <string>);
  cli-annotate(source, make(<cli-srcloc>, source: source, start: srcoff, end: srcoff));
end method;

define method cli-annotate(source :: <cli-string-source>, srcloc :: <cli-srcloc>)
 => (marks :: <string>);
  let string = concatenate(source-string(source), " "); // for final locations
  let marks :: <string> = "";

  for(char in string, posn from 0)
    let srcoff = cli-srcoff(posn, 0, posn);
    if(in-source-location?(srcloc, srcoff))
      marks := concatenate!(marks, "^");
    else
      marks := concatenate!(marks, " ");
    end;
  end for;

  marks;
end method;

define method cli-annotate(source :: <cli-vector-source>, srcloc :: <cli-srcloc>)
 => (marks :: <string>);
  let tokens = cli-tokenize(source);
  let code :: <string> = "  ";
  let marks :: <string> = "";

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

  marks;
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

// this allows for being just after the srcloc
define method in-completion-location?
    (srcloc :: <cli-srcloc>, other :: <cli-srcoff>)
 => (within? :: <boolean>);
  (other.source-offset-char
     >= srcloc.source-location-start-character)
    & (other.source-offset-char
         <= (srcloc.source-location-end-character + 1))
end method;
