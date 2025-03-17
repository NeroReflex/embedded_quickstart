# Embedded Quickstart

This is a collection of buildroot utilities used to quickly bootstrap linux embedded
applications, featuring a full-wayland embedded session with remote administration
capabilities for remote support.

## Usage

Configure buildroot initially with

```sh
make BR2_EXTERNAL=/path/to/embedded_quickstart menuconfig
```

Then use buildroot normally to:
  - Add to __BR2_ROOTFS_POST_IMAGE_SCRIPT__ as the last one the file *post_rootfs.sh*
  - Add to __BR2_ROOTFS_POST_BUILD_SCRIPT__ as the last one the file *pre_rootfs.sh*

It is also suggested that you __disable__ *the remount rootfs as r/w*, and manage it via /etc/fstab.

__WARNING__: The script that builds the image needs to perform filesystem operations such as creating
and mounting btrfs subvolumes, writing files attributes and others that requires the user to be root:
for this reason the user that runs buildroot __MUST__ a passwordless sudo user! Use a *fedora* Virtual Machine!

## Kernel

Include the *linux.conf* file to *Additional configuration fragment files* in Kernel menu.

## Bootloader

The following is bootloader-specific configurations: choose based on your bootloader of preference.

__WARNING__ The bootloader __MUST__ support BTRFS: in case of u-boot this is ensured by the configuration fragment.

### U-Boot

If you use u-boot you have to include the *uboot.conf* file to *Additional configuration fragment files* in
bootloaders -> u-boot.

__NOTE__ when generating a target for i.MX8 make sure to create u-boot-nodtb.bin (it is a file created when building u-boot.bin)
and it only needs to be specified as an additional u-boot binary format to be copied into BINARIES_DIR and therefore picked up
by mkimage.

## Weston

You can use a custom weston.ini file to customize weston settings.

The default file creates an rdp server using two files that __MUST__ be provided with a filesystem overlay:

  - /etc/freerdp/keys/server.key
  - /etc/freerdp/keys/server.crt

Those files can be generated with the command:

```sh
winpr-makecert -rdp -path $PWD -n server
```

You can read more about winpr-makecert [here](https://manpages.debian.org/testing/winpr-utils/winpr-makecert.1.en.html)

## Additional Notes

This project has been initially developed using buildroot [2024.02.11](https://buildroot.org/downloads/buildroot-2024.02.11.tar.gz).
Other versions known to work are:
  - [2024.11.2](https://buildroot.org/downloads/buildroot-2024.11.2.tar.gz)
