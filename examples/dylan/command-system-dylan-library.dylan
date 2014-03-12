module: dylan-user

define library command-system-dylan
  use common-dylan;
  use io;
  use system;
  use strings;
  use tty;
  use command-system;
  use tty;
  use release-info;
  use projects;
  use user-projects;
  use registry-projects;
  use environment-protocols;
  use environment-reports;
  use dfmc-common;
  use dfmc-environment-projects;
  use dfmc-environment-database;
  use dfmc-back-end-implementations;
end library;

define module command-system-dylan
  use common-dylan;
  use streams;
  use format,
    import: { format };
  use format-out,
    import: { format-out };
  use standard-io;
  use file-system;
  use locators;
  use strings;

  use tty;
  use command-system;
  use tty;

  use release-info;

  use projects, import: { default-build-script };
  use environment-protocols,
    exclude: { application-filename, application-arguments, parameter-name };
  use environment-reports;
end module;
