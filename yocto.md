# Yocto

This document is about what to do with yocto.

## Rust

Create /opt/Qt/yocto_arch.sh

```
#!/bin/bash
exec aarch64-poky-linux-gcc \
  -mcpu=cortex-a53+crc+crypto \
  -mbranch-protection=standard \
  -fstack-protector-strong \
  -O2 \
  -D_FORTIFY_SOURCE=2 \
  -Wformat \
  -Wformat-security \
  -Werror=format-security \
  --sysroot=/opt/Qt/6.10.1/Boot2Qt/imx8mm-var-dart/toolchain/sysroots/cortexa53-crypto-poky-linux \
  -B/opt/Qt/6.10.1/Boot2Qt/imx8mm-var-dart/toolchain/sysroots/cortexa53-crypto-poky-linux/usr/lib/aarch64-poky-linux/13.4.0 \
  -L/opt/Qt/6.10.1/Boot2Qt/imx8mm-var-dart/toolchain/sysroots/cortexa53-crypto-poky-linux/lib \
  -L/opt/Qt/6.10.1/Boot2Qt/imx8mm-var-dart/toolchain/sysroots/cortexa53-crypto-poky-linux/usr/lib \
  "$@"
```

and set it to executable:

```sh
chmod a+x /opt/Qt/yocto_arch.sh
```

in the project you want to compile add a .cargo/config.toml
```toml
[target.aarch64-unknown-linux-gnu]
linker = "/home/mitec/Git-projects/SW008/aarch64-rust-gcc"

[build]
target = "aarch64-unknown-linux-gnu"
```

Source the setup env file:

```sh
source ./opt/Qt/6.10.1/Boot2Qt/imx8mm-var-dart/toolchain/environment-setup-cortexa53-crypto-poky-linux
```

__NOTE__ It might be needed to have rustup and add the specific target beforehand

__WARNING__ If c libraries fails:

```sh
export OPENSSL_DIR=/opt/Qt/6.10.1/Boot2Qt/imx8mm-var-dart/toolchain/sysroots/cortexa53-crypto-poky-linux/usr
```