AGREETY_VERSION = 0.10.3
AGREETY_LICENSE = GPLv3
AGREETY_SITE = $(call github,kennylevinsen,greetd,$(GREETD_VERSION))
AGREETY_DEPENDENCIES = host-rustc
AGREETY_SUBDIR = agreety

$(eval $(cargo-package))
