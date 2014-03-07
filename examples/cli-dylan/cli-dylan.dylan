module: cli-dylan

define class <dylan-cli> (<object>)
  slot dylan-current-project :: false-or(<project-object>) = #f;
end class;


define method dylan-project-named (cli :: <dylan-cli>, string :: <string>)
 => (project :: false-or(<project-object>));
  any?(method (project)
        => (project :: false-or(<project-object>));
         (project-name(project) = as-lowercase(string)) & project;
       end,
       open-projects());
end method;

define method dylan-project (cli :: <dylan-cli>, parameter :: false-or(<string>))
 => (project :: false-or(<project-object>));
  if (parameter)
    dylan-project-named(cli, parameter);
  else
    dylan-current-project(cli);
  end;
end method;



define class <cli-open-dylan-project> (<cli-parameter>)
end class;

define method node-complete (param :: <cli-open-dylan-project>, parser :: <cli-parser>, token :: false-or(<cli-token>))
 => (completions :: <list>);
  let names = map(project-name, open-projects());
  let compls =
    if (token)
      let string = as-lowercase(token-string(token));
      let compls = choose(rcurry(starts-with?, string), names);
      compls;
    else
      names;
    end;
  as(<list>, compls);
end method;

define class <cli-dylan-project> (<cli-parameter>)
end class;

define method node-complete (param :: <cli-dylan-project>, parser :: <cli-parser>, token :: false-or(<cli-token>))
 => (completions :: <list>);
  let names = map(project-name, open-projects());
  let compls =
    if (token)
      let string = as-lowercase(token-string(token));
      let compls = choose(rcurry(starts-with?, string), names);
      unless (member?(string, compls, test: \=)
                | member?(longest-common-prefix(names), compls, test: \=))
        compls := add!(compls, string);
      end;
      compls;
    else
      names;
    end;
  as(<list>, compls);
end method;

define class <cli-report-type> (<cli-parameter>)
end class;

define method node-complete (param :: <cli-report-type>, parser :: <cli-parser>, token :: false-or(<cli-token>))
 => (completions :: <list>);
  let names = map(curry(as, <string>), key-sequence(available-reports()));
  let compls =
    if (token)
      let string = as-lowercase(token-string(token));
      choose(rcurry(starts-with?, string), names);
    else
      names;
    end;
  as(<list>, compls);
end method;


define function find-project-for-library
    (library-name :: <symbol>) => (project :: false-or(<project-object>))
  find-project(as(<string>, library-name))
    | begin
        let library-info = find-library-info(library-name);
        if (library-info)
          let location = info-location(library-info);
          location & open-project-from-locator(as(<file-locator>, location))
        end
      end
end function find-project-for-library;

define function open-project-from-locator (locator :: <file-locator>)
 => (project :: false-or(<project-object>), invalid? :: <boolean>)
  let pathname = merge-locators(expand-pathname(locator), working-directory());
  let extension = locator-extension(pathname);
  select (extension by \=)
    lid-file-extension() =>
      values(import-project-from-file(pathname), #f);
    project-file-extension() =>
      values(open-project(pathname), #f);
    executable-file-extension() =>
      values(create-exe-project-from-file(pathname), #f);
    otherwise =>
      if (~extension)
        let library-name = as(<symbol>, locator.locator-base);
        values(find-project-for-library(library-name), #f)
      else
        values(#f, #t);
      end;
  end;
end function;

define constant $cli = make(<dylan-cli>);


define cli-root $dylan-cli;

define cli-command show dylan version ($dylan-cli)
  implementation
    format-out("%s\n", release-full-name());
end;

define cli-command show dylan copyright ($dylan-cli)
  implementation
    format-out("%s", release-full-copyright());
end;

define cli-command show project ($dylan-cli)
  simple parameter project :: <string>,
    node-class: <cli-dylan-project>;
  implementation
    begin
      let p = dylan-project($cli, project);
      if (p)
        format-out("Project %s\n\n", project-name(p));
        format-out("  class %s\n", object-class(p));
        format-out("  directory %s\n", project-directory(p));
      end;
      for (p in open-projects())
        format-out("Open %s\n", project-name(p));
      end;
    end;
end;

define cli-command open ($dylan-cli)
  simple parameter project :: <string>,
    node-class: <cli-dylan-project>;
  implementation
    begin
      format-out("Opening %s!\n", project);
      let (pobj, invalid?) = open-project-from-locator(as(<file-locator>, project));
      case
        pobj =>
          open-project-compiler-database
            (pobj, warning-callback: curry(note-compiler-warning, $cli, pobj));

          format-out("Opened project %s (%s)",
                     pobj.project-name,
                     pobj.project-filename);

          pobj.project-opened-by-user? := #t;

          dylan-current-project($cli) := pobj;

          pobj;
        invalid? =>
          error("Cannot open '%s' as it is not a project", project);
        otherwise =>
          error("Unable to open project '%s'", project);
      end
    end;
end;

define cli-command close ($dylan-cli)
  simple parameter project :: <string>,
    node-class: <cli-dylan-project>;
  implementation
    begin
      format-out("Closing %s!\n", project);
      let p = dylan-project($cli, project);
      close-project(p);
    end;
end;

define cli-command build ($dylan-cli)
  simple parameter project :: <string>,
    node-class: <cli-dylan-project>;
  implementation
    begin
      let p = dylan-project($cli, project);
      if (p)
        format-out("Building project %s\n", project-name(p));
        if(build-project(p,
                         process-subprojects?: #t,
                         link?: #f,
                         save-databases?: #t,
                         progress-callback:    curry(note-build-progress, $cli, p),
                         warning-callback:     curry(note-compiler-warning, $cli, p),
                         error-handler:        curry(compiler-condition-handler, $cli)))
          link-project
            (p,
             build-script: default-build-script(),
             process-subprojects?: #t,
             progress-callback:    curry(note-build-progress, $cli, p),
             error-handler:        curry(compiler-condition-handler, $cli));
        end;
      end;
    end;
end;

define cli-command clean ($dylan-cli)
  simple parameter project :: <string>,
    node-class: <cli-dylan-project>;
  implementation
    begin
      let p = dylan-project($cli, project);
      if (p)
        format-out("Cleaning project %s\n", project-name(p));
        clean-project(p, process-subprojects?: #f);
      end;
    end;
end;

define cli-command report ($dylan-cli)
  simple parameter report :: <symbol>,
    node-class: <cli-report-type>;
  named parameter project :: <string>,
    node-class: <cli-dylan-project>;
  named parameter format :: <symbol>,
    node-class: <cli-oneof>,
    alternatives: #("text", "dot", "html", "xml", "rst");
  implementation
    begin
      let p  = dylan-project($cli, project);
      let info = find-report-info(report);
      unless (format)
        format := #"text";
      end;
      case
        info =>
          if (~member?(format, info.report-info-formats))
            error("The %s report does not support the '%s' format",
                  report, format);
          end;
          let result = make(info.report-info-class,
                            project: p,
                            format: format);
          write-report(*standard-output*, result);
        otherwise =>
          error("No such report '%s'", report);
      end
    end;
end;



define variable *lastmsg* = #f;

define method note-build-progress
    (cli :: <dylan-cli>, project :: <project-object>,
     position :: <integer>, range :: <integer>,
     #key heading-label, item-label)
 => ();
  let last-item-label = *lastmsg*;
  if (item-label & ~empty?(item-label) & item-label ~= last-item-label)
    *lastmsg* := item-label;
    format-out("%s\n", item-label);
    force-output(*standard-output*);
  end
end method note-build-progress;

define method note-compiler-warning
    (cli :: <dylan-cli>, project :: <project-object>,
     warning :: <warning-object>)
 => ();
  let stream = *standard-output*;
  new-line(stream);
  print-environment-object-name(stream, project, warning, full-message?: #t);
  new-line(stream)
end method note-compiler-warning;


define method compiler-condition-handler
    (context :: <dylan-cli>,
     handler-type == #"link-error", message :: <string>)
 => (filename :: singleton(#f))
  error("Link failed: %s", message)
end method compiler-condition-handler;

define method compiler-condition-handler
    (context :: <dylan-cli>,
     handler-type == #"link-warning", warning-message :: <string>)
 => (filename :: singleton(#f))
  format-out("%s\n", warning-message);
  force-output(*standard-output*);
end method compiler-condition-handler;

define method compiler-condition-handler
    (context :: <dylan-cli>,
     handler-type == #"fatal-error", message :: <string>)
 => (filename :: singleton(#f))
  error("Fatal error: %s", message)
end method compiler-condition-handler;

define method compiler-condition-handler
    (context :: <dylan-cli>,
     handler-type :: <symbol>,
     warning-message :: <string>)
 => (yes? :: <boolean>)
  format-out("missing handler for %s: %s\n", handler-type, warning-message);
  force-output(*standard-output*);
end method compiler-condition-handler;


tty-cli-main(application-name(), application-arguments(),
             application-controlling-tty(),
             $dylan-cli);
