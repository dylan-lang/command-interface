module: dylan-user

define library command-system-demo
  use common-dylan;
  use io;
  use command-system;
  use tty; // XXX eliminate
end library;

define module command-system-demo
  use common-dylan;
  use streams;
  use format,
    import: { format };
  use format-out,
    import: { format-out };
  use standard-io;
  use command-system;
  use tty; // XXX eliminate
end module;
