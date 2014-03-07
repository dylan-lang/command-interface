module: dylan-user

define library cli-test
  use common-dylan;
  use testworks;
  use io;
  use cli;
  use source-records;
end library;

define module cli-test
  use common-dylan, exclude: { format-to-string };
  use format-out;
  use testworks;
  use cli;
  use source-records;
end module;
