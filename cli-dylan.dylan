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

define method dylan-project (cli :: <dylan-cli>, parser :: <cli-parser>, parameter :: <symbol>)
 => (project :: false-or(<project-object>));
  let project = #f;
  let pname = parser-get-parameter(parser, parameter);
  if (pname)
    project := dylan-project-named(cli, pname);
  end;
  if (~project)
    project := dylan-current-project(cli);
  end;
  project;
end method;

define constant $dylan-cli = make(<dylan-cli>);

define constant $dylan-cli-external = make(<cli-root>);
define constant $dylan-cli-interactive = make(<cli-root>);

begin
  root-add-bash-completion($dylan-cli-external);
  root-add-help($dylan-cli-external);
  root-add-help($dylan-cli-interactive);
end;

define function dylan-define-command (symbols :: <object>,
                                      #rest keys,
                                      #key parameters :: false-or(<function>) = #f,
                                           handler :: <function>,
                                           interactive? :: <boolean> = #t,
                                           external? :: <boolean> = #t,
                                      #all-keys)
 => ();
  let real-handler = method (parser :: <cli-parser>)
                       block ()
                         handler($dylan-cli, parser);
                       exception (err :: <error>)
                         format-out("An error occured:\n%s\n",
                                    condition-to-string(err));
                       end;
                     end;
  if(external?)
    let external-command
      = apply(root-define-command, $dylan-cli-external, symbols,
              handler:, real-handler,
              keys);
    if(parameters)
      parameters(external-command);
    end;
  end;
  if(interactive?)
    let interactive-command
      = apply(root-define-command, $dylan-cli-interactive, symbols,
              handler:, real-handler,
              keys);
    if(parameters)
      parameters(interactive-command);
    end;
  end;
end function;

define function run-interactive()
  let t = application-controlling-tty();
  let e = make(<tty-cli>,
               root-node: $dylan-cli-interactive);
  tty-run(t, e);
end function;

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

dylan-define-command (quit:,
                      external?: #f,
                      handler: method (c :: <dylan-cli>, p :: <cli-parser>)
                                 format-out("Goodbye!\n");
                                 force-output(*standard-output*);
                                 exit-application(0);
                               end);

dylan-define-command (#(show:, dylan:, version:),
                      help: "Show the version of the dylan system",
                      handler: method (c :: <dylan-cli>, p :: <cli-parser>)
                                 format-out("%s\n", release-full-name());
                               end);

dylan-define-command (#(show:, dylan:, copyright:),
                      help: "Show the copyright of the dylan system",
                      handler: method (c :: <dylan-cli>, p :: <cli-parser>)
                                 format-out("%s", release-full-copyright());
                               end);

dylan-define-command (#(show:, environment:),
                      help: "Show information about the environment",
                      handler: method (c :: <dylan-cli>, p :: <cli-parser>)
                                 format-out("Environment!\n");
                               end);

dylan-define-command (#(show:, project:),
                      help: "Show information about a project",
                      parameters: method (c :: <cli-command>)
                                    make-inline-param(c, name:);
                                  end,
                      handler: method (c :: <dylan-cli>, p :: <cli-parser>)
                                 let project = dylan-project(c, p, name:);
                                 if (project)
                                   format-out("Project %s\n\n", project-name(project));
                                   format-out("  class %s\n", object-class(project));
                                   format-out("  directory %s\n", project-directory(project));
                                 end;
                                 for (p in open-projects())
                                   format-out("Open %s\n", project-name(p));
                                 end;
                               end);


dylan-define-command (#(open:),
                      help: "Open a project",
                      external?: #f,
                      parameters: method (c :: <cli-command>)
                                    make-inline-param(c, name:, required?: #t);
                                  end,
                      handler: method (c :: <dylan-cli>, p :: <cli-parser>)
                                 let filename = parser-get-parameter(p, name:);
                                 format-out("Opening %s!\n", filename);
                                 let (project, invalid?)
                                   = open-project-from-locator(as(<file-locator>, filename));
                                 case
                                   project =>
                                     open-project-compiler-database
                                       (project,
                                        warning-callback:     curry(note-compiler-warning, c, project));
                                     project.project-opened-by-user? := #t;
                                     format-out("Opened project %s (%s)", project.project-name,
                                                project.project-filename);
                                     dylan-current-project(c) := project;
                                     project;
                                   invalid? =>
                                     error("Cannot open '%s' as it is not a project", filename);
                                   otherwise =>
                                     error("Unable to open project '%s'", filename);
                                 end
                               end);

dylan-define-command (#(close:),
                      help: "Close a project",
                      external?: #f,
                      parameters: method (c :: <cli-command>)
                                    make-inline-param(c, name:);
                                  end,
                      handler: method (c :: <dylan-cli>, p :: <cli-parser>)
                                 format-out("Closing!\n");
                               end);

dylan-define-command (#(report:),
                      help: "Report on a project",
                      parameters: method (c :: <cli-command>)
                                    make-inline-param(c, name:);
                                    make-named-param(c, type:);
                                    make-named-param(c, format:);
                                  end,
                      handler: method (c :: <dylan-cli>, p :: <cli-parser>)
                                 let project  = dylan-project(c, p, name:);
                                 let report   = as(<symbol>,
                                                   parser-get-parameter(p, type:,
                                                                        default: "warnings"));
                                 let format   = as(<symbol>,
                                                   parser-get-parameter(p, format:,
                                                                        default: "text"));
                                 let info     = find-report-info(report);
                                 case
                                   info =>
                                     if (~member?(format, info.report-info-formats))
                                       error("The %s report does not support the '%s' format",
                                             report, format);
                                     end;
                                     let report
                                     = make(info.report-info-class,
                                            project: project,
                                            format: format);
                                     write-report(*standard-output*, report);
                                   otherwise =>
                                     error("No such report '%s'", report);
                                 end
                               end);


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


dylan-define-command (#(build:),
                      help: "Build a project",
                      parameters: method (c :: <cli-command>)
                                    make-inline-param(c, name:);
                                  end,
                      handler: method (c :: <dylan-cli>, p :: <cli-parser>)
                                 let p = dylan-project(c, p, name:);
                                 if (p)
                                   format-out("Building project %s\n", project-name(p));
                                   if(build-project(p,
                                                    process-subprojects?: #t,
                                                    link?: #f,
                                                    save-databases?: #t,
                                                    progress-callback:    curry(note-build-progress, c, p),
                                                    warning-callback:     curry(note-compiler-warning, c, p),
                                                    error-handler:        curry(compiler-condition-handler, c)
                                                      ))
                                     link-project
                                       (p,
                                        build-script: default-build-script(),
                                        process-subprojects?: #t,
                                        progress-callback:    curry(note-build-progress, c, p),
                                        error-handler:        curry(compiler-condition-handler, c));

                                   end;
                                 end;
                               end);

dylan-define-command (#(clean:),
                      help: "Clean a project",
                      parameters: method (c :: <cli-command>)
                                    make-inline-param(c, name:);
                                  end,
                      handler: method (c :: <dylan-cli>, p :: <cli-parser>)
                                 let p = dylan-project(c, p, name:);
                                 if (p)
                                   format-out("Cleaning project %s\n", project-name(p));
                                   clean-project(p, process-subprojects?: #f);
                                 end;
                               end);


define function main (name :: <string>, arguments :: <vector>)
  if(empty?(arguments))
    run-interactive();
  else
    let source = make(<cli-vector-source>, strings: arguments);
    let parser = make(<cli-parser>, source: source,
                      initial-node: $dylan-cli-external);
    
    let tokens = cli-tokenize(source);
    
    block ()
      parser-parse(parser, tokens);
      parser-execute(parser);
    exception (pe :: <cli-parse-error>)
      format(*standard-error*,
             " %s\n %s\n%s\n",
             source-string(source),
             cli-annotate(source,
                          token-srcloc(pe.error-token)),
             condition-to-string(pe));
      force-output(*standard-error*);
    end;
  end if;
  
  exit-application(0);
end function main;

main(application-name(), application-arguments());
