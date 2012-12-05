module: dylan-user

define library cli-dylan
  use common-dylan;
  use io;
  use system;
  use cli;
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

define module cli-dylan
  use common-dylan;
  use streams;
  use format,
    import: { format };
  use format-out,
    import: { format-out };
  use standard-io;
  use file-system;
  use locators;

  use cli;
  use tty;

  use release-info;

  use projects;
  use environment-protocols,
    exclude: { application-filename, application-arguments };
  use environment-reports;
end module;
