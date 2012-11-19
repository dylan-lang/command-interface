module: dylan-user

define library cli
  use common-dylan;
  use source-records;
  use io;
  use c-ffi;
  use system;
  use strings;
end library;

define module cli
  use common-dylan;
  use streams;
  use format;
  use print;
  use pprint;
  use strings;
  use file-system;
  use locators;
  use standard-io;
  use format-out;
  use operating-system;
  use source-records;
  use c-ffi;
end module;
