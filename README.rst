Command Interface System
========================

|Build status|

.. image:: https://github.com/dylan-lang/command-interface/actions/workflows/build-and-test.yml/badge.svg
	   :target: https://github.com/dylan-lang/command-interface/actions/workflows/build-and-test.yml

|Documentation|

.. image:: https://github.com/dylan-lang/command-interface/actions/workflows/build-and-deploy-documentation.yml/badge.svg
	   :target: https://github.com/dylan-lang/command-interface/actions/workflows/build-and-deploy-documentation.yml

This is a system for building command-driven interfaces in Dylan.

It can currently be used to declaratively design terminal-based
command interfaces, commonly called shells or CLIs.

We also strive to implement graphical command interfaces in a similar
manner to `Symbolics Genera
<https://en.wikipedia.org/wiki/Genera_(operating_system)>`_, including
support for full graphical and markup output.

Compiling
---------

Update library dependencies::

    dylan update

Build the library, tests and demo with::

    dylan build --all

Run the demo::

    _build/bin/command-interface-demo

And the tests::

    _build/bin/command-interface-test

Completion in bash
------------------

Our system integrates with bash completion. This allows one
to implement a binary that can be used both as an
interactive shell and from the system shell.

To enable this feature you need to load the shell snippet
printed by the following command into your shell::

    _build/bin/command-interface-demo bashcomplete

Once you do this you can complete and execute all commands
that would be available inside the shell.

This feature is automatically available to library users.
