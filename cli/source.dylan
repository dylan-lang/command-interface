module: cli
synopsis: CLI source records.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file COPYING


/* TOKENS */

define class <cli-token> (<object>)
  slot token-string :: <string>,
    init-keyword: string:;
  slot token-type :: <symbol> = #"unknown",
    init-keyword: type:;
  slot token-srcloc :: <source-location>,
    init-keyword: srcloc:;
end class;


/* SOURCE RECORDS */

define abstract class <cli-source> (<source-record>)
end class;

define generic cli-tokenize (source :: <cli-source>)
 => (tokens :: <sequence>);

define generic source-string (source :: <cli-source>)
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

/* Tokenize a CLI string
 *
 * This uses a hand-written DFA for tokenization.
 *
 * XXX Misses line counting and line offsets in srclocs.
 */
define method cli-tokenize (source :: <cli-string-source>)
 => (tokens :: <sequence>);
  // source string to tokenize
  let string = source-string(source);
  // collected tokens
  let tokens = #();

  // lexer DFA state
  let state = #"initial";
  // token building state
  let ttype :: false-or(<symbol>) = #f;
  let tstart :: <integer> = 0;
  let tend :: <integer> = 0;

  // these can be used at epsilon
  local
    method reset()
      ttype := #f;
      tstart := 0;
      tend := 0;
      state := #"initial";
    end,
    method reduce()
      //format-out("  reduce()\n");
      let srcloc = make-source-location(source,
                                        tstart, 0, tstart,
                                        tend, 0, tend);
      let token = make(<cli-token>,
                       type: ttype,
                       string: copy-sequence(string,
                                              start: tstart,
                                              end: tend + 1),
                       srcloc: srcloc);
      //format-out("  token \"%s\" type %= start %d end %d\n",
      //           token-string(token), token-type(token),
      //           tstart, tend);
      tokens := add(tokens, token);
      reset();
    end;

  // the lexer itself
  for (char in string, offset from 0)
    // someone hand me an IDE with code folding...
    local
      method shift(next-state)
        //format-out("  shift(%=)\n", next-state);
        recognize(next-state);
        tend := offset;
        state := next-state;
      end,
      method recognize(type)
        // use this to override token type
        // before shift() if state and type differ
        if (~ttype)
          ttype := type;
          tstart := offset;
        end
      end,
      method special();
        //format-out("  special()\n");
        shift(#"special");
        reduce();
      end,
      method initial()
          case
            char.whitespace? =>
              shift(#"whitespace");
            char = ';' =>
              special();
            char = '?' =>
              special();
            char = '|' =>
              special();
            char = '"' =>
              shift(#"dquote");
            char = '\\' =>
              recognize(#"word");
              shift(#"word-backslash");
            char.graphic? =>
              shift(#"word");
            otherwise =>
              invalid("character not allowed here");
          end;
      end,
      method invalid (message)
        => ();
        signal(make(<cli-lexer-error>,
                    format-string: "Lexical error: %s",
                    format-arguments: vector(message),
                    source: source,
                    string: string,
                    srcoff: cli-srcoff(offset, 0, offset)));
      end;
    //format-out(" state %= char %= offset %d\n",
    //           state, char, offset);
    // lexer state machine (except for epsilon)
    select (state)
      #"initial" =>
        initial();
      #"whitespace" =>
        if (char.whitespace?)
          shift(#"whitespace");
        else
          reduce();
          initial();
        end;
      #"word" =>
        case
          char.whitespace? =>
            reduce();
            shift(#"whitespace");
          char = ';' =>
            reduce();
            special();
          char = '|' =>
            reduce();
            special();
          char = '"' =>
            reduce();
            shift(#"dquote");
          char = '\\' =>
            shift(#"word-backslash");
          char.graphic? =>
            shift(#"word");
          otherwise =>
            invalid("character not allowed here");
        end;
      #"word-backslash" =>
        if (char.graphic?)
          shift(#"word");
        else
          invalid("character not allowed here");
        end;
      #"dquote" =>
        select (char)
          '"' =>
            shift(#"dquote");
            reduce();
          '\\' =>
            shift(#"dquote-backslash");
          otherwise =>
            shift(#"dquote");
        end;
      #"dquote-backslash" =>
        if (char.graphic?)
          shift(#"dquote");
        else
          invalid("character not allowed here");
        end;
    end;
    //format-out("  now in %= type %= start %d end %d\n",
    //           state, ttype, tstart, tend);
  end for;

  let source-length = size(string) - 1; // XXX defensive
  local method invalid-eof(message)
          signal(make(<cli-lexer-error>,
                      format-string: "Lexical error: %s",
                      format-arguments: vector(message),
                      source: source,
                      string: string,
                      srcoff: cli-srcoff(source-length, 0, source-length)));
        end;

  //format-out(" state %=\n", state);

  // handle epsilon / end of source
  select (state)
    #"initial", #"whitespace" =>
      #f;
    #"word" =>
      reduce();
    #"word-backslash" =>
      invalid-eof("Escaping backslash at end of file");
    #"dquote", #"dquote-backslash" =>
      invalid-eof("Unclosed dquote at end of file");
    otherwise =>
      invalid-eof("BUG: Unknown lexer state at end of file");
  end;

  // we collect in reverse order, so reverse the result
  let tokens = reverse(tokens);
  let types = map(token-type, tokens);
  choose-by(curry(\~=, #"whitespace"), types, tokens);
end method;

/* CLI source code provided as a vector of strings
 *
 * This is intended for commands being parsed from
 * program arguments, such as when we are in bash
 * completion mode.
 *
 * With regards to source locations and the source
 * string we simply join the strings with " ".
 *
 * XXX this needs to escape strings
 *     using dquote in the source
 */
define class <cli-vector-source> (<cli-source>)
  slot source-vector :: <sequence>,
    required-init-keyword: strings:;
end class;

define method source-string (source :: <cli-vector-source>)
 => (string :: <string>);
  join(source-vector(source), " ");
end method;

define method cli-tokenize (source :: <cli-vector-source>)
 => (tokens :: <sequence>);
  let tokens :: <list> = #();
  let concat :: <string> = "";
  for (string in source-vector(source), posn from 0)
    if (posn > 0)
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

define method cli-annotate (source :: <cli-source>, srcoff :: <cli-srcoff>)
 => (marks :: <string>);
  cli-annotate(source, make(<cli-srcloc>, source: source, start: srcoff, end: srcoff));
end method;

define method cli-annotate (source :: <cli-string-source>, srcloc :: <cli-srcloc>)
 => (marks :: <string>);
  // expand source string for final/epsilon error locations
  let string = concatenate(source-string(source), " ");
  // collect string with error markers
  let marks :: <string> = "";
  for (char in string, posn from 0)
    let srcoff = cli-srcoff(posn, 0, posn);
    if (in-source-location?(srcloc, srcoff))
      marks := concatenate!(marks, "^");
    else
      marks := concatenate!(marks, " ");
    end;
  end for;
  // return the result
  marks;
end method;

define method cli-annotate (source :: <cli-vector-source>, srcloc :: <cli-srcloc>)
 => (marks :: <string>);
  let tokens = cli-tokenize(source);
  let code :: <string> = "  ";
  let marks :: <string> = "";

  for (token in tokens, posn from 0)
    if (posn > 0)
      code := concatenate!(code, " ");
      marks := concatenate!(marks, " ");
    end;

    let str = token-string(token);

    code := concatenate!(code, str);

    if (in-source-location?(srcloc, token-srcloc(token)))
      for (i from 0 below str.size)
        marks := concatenate!(marks, "^");
      end
    else
      for (i from 0 below str.size)
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

define method cli-srcoff (char, line, column)
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
