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