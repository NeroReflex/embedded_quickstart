# Embedded Quickstart

This is a collection of buildroot utilities used to quickly bootstrap linux embedded
applications, featuring a full-wayland embedded session with remote administration
capabilities for remote support.

Minimal yocto support is also in-development: this is used to create a disk image in
a way that the updater of choice can use.

## Yocto

To use yocto you will need to ensure the bootloader and the kernel are both compiled with btrfs
support, and in case of the kernel such support is linked inside the kernel (__BTRFS_FS__ is *y* and not *m*).

Once the rootfs and additional booting files have been generated you have to call this script like this:

```sh
sudo bash ./genimage.sh /path/to/yocto/build-imx8mm-var-dart/tmp/deploy/images/imx8mm-var-dart/ factory
```

And a disk_image.img will be generated. The hardware type is deducted from the presence of files in the build
result, so if you see *Unsupported hardware.* you will need to add support for your hardware.

To add support to a new hardware add partitions in a way the hardware will boot and as the last partition on the
disk put the rootfs.

## Usage

Configure buildroot initially with

```sh
make BR2_EXTERNAL=/path/to/embedded_quickstart menuconfig
```

Then use buildroot normally to:
  - Add to __BR2_ROOTFS_POST_IMAGE_SCRIPT__ as the last one the file *post_rootfs.sh*
  - Add to __BR2_ROOTFS_POST_BUILD_SCRIPT__ as the last one the file *pre_rootfs.sh*

It is also suggested that you __disable__ *the remount rootfs as r/w*, and manage it via /etc/fstab.

__NOTE__: if you specify an additional argument to the script (via the __BR2_ROOTFS_POST_IMAGE_SCRIPT_ARGS__ property) an update file will be generated.

__WARNING__: The script that builds the image needs to perform filesystem operations such as creating
and mounting btrfs subvolumes, writing files attributes and others that requires the user to be root:
for this reason the user that runs buildroot __MUST__ a passwordless sudo user! Use a *fedora* Virtual Machine!

__NOTE__: if compilation fails (probably building host-m4 with a new gcc version) try to launch it with these flags:

```sh
export HOST_CFLAGS="-Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration -Wno-error=format-overflow=  -Wno-int-conversion -Wno-attributes -std=gnu17"
export HOST_CXXFLAGS=$HOST_CFLAGS
make -j$(nproc)
```

### Kernel

Include the *linux.conf* file to *Additional configuration fragment files* in Kernel menu.

### Bootloader

The following is bootloader-specific configurations: choose based on your bootloader of preference.

__WARNING__ The bootloader __MUST__ support BTRFS: in case of u-boot this is ensured by the configuration fragment.

### U-Boot

If you use u-boot you have to include the *uboot.conf* file to *Additional configuration fragment files* in
bootloaders -> u-boot.

__NOTE__ when generating a target for i.MX8 make sure to create u-boot-nodtb.bin (it is a file created when building u-boot.bin)
and it only needs to be specified as an additional u-boot binary format to be copied into BINARIES_DIR and therefore picked up
by mkimage.

### Init

By default the kernel run */init* if started on a initramfs or */usr/init* if a initramfs is not in use.

Buildroot automatically places links to start the configured init system, however shall you want to use either stuPID1 or
atomrootfs you will need to use a skeleton that defines relevant links.

You can also customize the bootloader to chanke kernel cmdline init= or rdinit= to point directly to the executable you want to run.

atomrootfs will be installed in */usr/bin/atomrootfsinit*.

### Weston

You can use a custom weston.ini file to customize weston settings.

The default file creates an rdp server using two files that __MUST__ be provided with a filesystem overlay:

  - /etc/freerdp/keys/server.key
  - /etc/freerdp/keys/server.crt

Those files can be generated with the command:

```sh
winpr-makecert -rdp -path $PWD -n server
```

You can read more about winpr-makecert [here](https://manpages.debian.org/testing/winpr-utils/winpr-makecert.1.en.html)

## Flash and Update

You can use this command to flash the resulting image after uploading it to a website:

```sh
curl http://192.168.0.93:8080/disk_image.img > /dev/mmcblk2
```

then, to update the image upload the .btrfs.xz file to a website and then:

```sh
curl http://192.168.0.93:8080/v1_0.btrfs.xz | xz -d | btrfs receive "/mnt/deployments"
/mnt/deployments/v1_0/usr/lib/embedded_quickstart/install
btrfs subvolume show /mnt/deployments/v1_0/ # take note of "Subvolume ID"
btrfs subvolume set-default $subvolid /mnt
```

__WARNING__: This method of updating skips every check and can install everything, therefore it is suitable __ONLY__
for a quick testing. Use mender_modules instead and configure mender appropriately for updating production devices.

## Adding support for a device

To add support for a new (family) of device(s) edit post_rootfs.sh and create a specific case catching your required disk layout.

Search for 'Unsupported hardware.' in the source code.

## Additional Notes

This project has been initially developed using buildroot [2024.02.11](https://buildroot.org/downloads/buildroot-2024.02.11.tar.gz).
Other versions known to work are:
  - [2024.11.2](https://buildroot.org/downloads/buildroot-2024.11.2.tar.gz)
  - [2025.02.3](https://buildroot.org/downloads/buildroot-2025.02.3.tar.gz)
  - [2025.02.3](https://buildroot.org/downloads/buildroot-2025.05.tar.gz)
