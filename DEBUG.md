# Debugging the kernel

Compile linux including the configuration fragment file *linux-debug.conf*.

The output file will be located in *$BUILDROOT/output/build/linux-<hash>/vmlinux*: load this file into gdb.

## Configuration

This is for debugging the userspace:

```
BR2_DEBUG_3=y
BR2_ENABLE_DEBUG=y # enable debug symbol in packages
BR2_OPTIMIZE_0=y
```

To build a debug kernel version use *linux-debug.conf* instead of *linux.conf* as kernel configuration fragment.

## Kernel Debugging

These instructions are valid with a SEGGER J-Link PRO: install the official software package from SEGGER website.

Include GDB support from buildroot manuconfig -> Toolchain.

Start the target, but block it in the bootloader.

Start it this way:

```sh
JLinkGDBServer -device MIMX8MM1_A53_0 -notimeout -if JTAG -nolocalhostonly
```

Remeber to change the device type as needed.

Then do the follogin:

```sh
cd $BUILDROOT_DIR/output/host/
./bin/aarch64-linux-gdb ../build/linux/vmlinux

# once inside GDB check symbols have being loaded and then
target remote-extended 10.0.0.54:2331
continue
```

Now make the bootloader continue boot and debugging should work.
