STUPID1_VERSION = 0.1.1
STUPID1_LICENSE = GPLv2
STUPID1_SITE = $(call github,NeroReflex,stuPID1,v$(STUPID1_VERSION))
STUPID1_DEPENDENCIES = host-rustc

$(eval $(cargo-package))
