AGREETY_VERSION = 0.10.3
AGREETY_LICENSE = GPL-3.0
AGREETY_SITE = $(call github,kennylevinsen,greetd,$(AGREETY_VERSION))
AGREETY_DEPENDENCIES = host-rustc
AGREETY_SUBDIR = agreety

$(eval $(cargo-package))
