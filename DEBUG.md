# Debugging the kernel

Compile linux including the configuration fragment file *linux-debug.conf*.

The output file will be located in *$BUILDROOT/output/build/linux-<hash>/vmlinux*: load this file into gdb.
