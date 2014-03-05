module: dylan-user

define library cli-demo
  use common-dylan;
  use io;
  use cli;
end library;

define module cli-demo
  use common-dylan;
  use streams;
  use format,
    import: { format };
  use format-out,
    import: { format-out };
  use standard-io;

  use cli;
  use tty;
end module;
