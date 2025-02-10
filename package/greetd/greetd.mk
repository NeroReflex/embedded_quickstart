GREETD_VERSION = 0.10.3
GREETD_LICENSE = GPLv3
GREETD_SITE = $(call github,kennylevinsen,greetd,$(GREETD_VERSION))
GREETD_DEPENDENCIES = host-rustc
GREETD_SUBDIR = greetd

$(eval $(cargo-package))
