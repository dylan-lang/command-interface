module: dylan-user

define library cli
  use common-dylan;
  use source-records;
  use io;
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
  use standard-io;
  use format-out;
  use operating-system;
  use source-records;
end module;
