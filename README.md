
This is a flexible CLI library for dylan in dylan

# Compiling

All dependencies are in opendylan itself.

Add a custom registry entry and build with:

$ dylan-compiler -build cli


# bash completion

The cli integrates with bash completion.

To enable it, say:

$ cli bashcomplete | source /proc/self/fd/0

