module: dylan-user

define library command-system-test
  use common-dylan;
  use testworks;
  use io;
  use command-system;
  use source-records;
end library;

define module command-system-test
  use common-dylan, exclude: { format-to-string };
  use format-out;
  use testworks;
  use command-system;
  use source-records;
end module;
