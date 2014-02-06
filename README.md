# Dylan CLI Library

This is a library for building command line interfaces in Dylan.

It can be used for build programs with an interactive shell
that supports completion and sophisticated self-documentation.

It is dynamic in the sense that command structure and
parameter completion can depend on runtime state.

## Compiling

All dependencies are in opendylan itself.

Add a custom registry entry and build with:

$ dylan-compiler -build cli

There is also a demo:

$ dylan-compiler -build cli-demo

As well as some tests:

$ dylan-compiler -build cli-test

## Completion in bash

The cli integrates with bash completion. This allows one
to implement a CLI binary that can be used both as an
interactive shell and from the system shell.

To enable this feature you need to load the shell snippet
printed by the following command into your shell:

$ cli-demo bashcomplete

Once you do this you can complete and execute all commands
that would be available inside the shell.

This feature is automatically available to library users.
