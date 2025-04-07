STUPID1_VERSION = 0.1.1
STUPID1_LICENSE = GPL-2.0-or-later
STUPID1_SOURCE = $(STUPID1_VERSION).tar.gz
STUPID1_SITE = https://github.com/NeroReflex/stuPID1/archive/refs/tags
STUPID1_DEPENDENCIES = host-rustc

$(eval $(cargo-package))
