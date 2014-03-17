Command Interface System
========================

This is a system for building command-driven interfaces in Dylan.

It can currently be used to declaratively design terminal-based
command interfaces, commonly called shells or CLIs.

We also strive to implement graphical command interfaces in a
similar manner to Symbolics Genera, including support for
full graphical and markup output.

Compiling
---------

All dependencies are in `Open Dylan`_ itself.

Just build with::

    $ dylan-compiler -build command-interface

There also is a demo::

    $ dylan-compiler -build command-interface-demo
    $ _build/bin/command-interface-demo

As well as some tests::

    $ dylan-compiler -build command-interface-test
    $ _build/bin/command-interface-test

Completion in bash
------------------

Our system integrates with bash completion. This allows one
to implement a binary that can be used both as an
interactive shell and from the system shell.

To enable this feature you need to load the shell snippet
printed by the following command into your shell::

    $ _build/bin/command-interface-demo bashcomplete

Once you do this you can complete and execute all commands
that would be available inside the shell.

This feature is automatically available to library users.

.. _Open Dylan: https://github.com/dylan-lang/opendylan
