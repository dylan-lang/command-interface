module: dylan-user

define library command-interface-demo
  use common-dylan;
  use io;
  use command-interface;
  use tty; // XXX eliminate
end library;

define module command-interface-demo
  use common-dylan;
  use streams;
  use format,
    import: { format };
  use format-out,
    import: { format-out };
  use standard-io;
  use command-interface;
  use tty; // XXX eliminate
end module;
