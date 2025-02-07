# Embedded Quickstart

This is a collection of buildroot utilities used to quickly bootstrap linux embedded
applications, featuring a full-wayland embedded session with remote administration
capabilities for remote support.

## Usage

Configure buildroot initially with

```sh
make BR2_EXTERNAL=/path/to/embedded_quickstart menuconfig
```

Then use buildroot normally.
