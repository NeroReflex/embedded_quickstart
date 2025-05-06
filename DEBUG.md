# Debugging the kernel

Compile linux including the configuration fragment file *linux-debug.conf*.

The output file will be located in *$BUILDROOT/output/build/linux-<hash>/vmlinux*: load this file into gdb.

## Configuration

```
BR2_DEBUG_3=y
BR2_ENABLE_DEBUG=y # enable debug symbol in packages
BR2_OPTIMIZE_0=y
```