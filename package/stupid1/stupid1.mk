STUPID1_VERSION = 1.1.3
STUPID1_LICENSE = GPL-2.0-or-later
STUPID1_SOURCE = $(STUPID1_VERSION).tar.gz
STUPID1_SITE = https://github.com/NeroReflex/stuPID1/archive/refs/tags
STUPID1_DEPENDENCIES = host-rustc
STUPID1_CARGO_BUILD_OPTS = --all-features
STUPID1_CARGO_INSTALL_OPTS = --all-features

$(eval $(cargo-package))
