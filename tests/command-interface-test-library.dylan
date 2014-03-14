module: dylan-user

define library command-interface-test
  use common-dylan;
  use testworks;
  use io;
  use command-interface;
  use source-records;
end library;

define module command-interface-test
  use common-dylan, exclude: { format-to-string };
  use format-out;
  use testworks;
  use command-interface;
  use source-records;
end module;
