STUPID1_VERSION = 1.0
#STUPID1_SITE = http://example.com/mypackage
#STUPID1_SOURCE = mypackage-$(MYPACKAGE_VERSION).tar.gz
STUPID1_LICENSE = MIT

STUPID1_SITE = $(call github,NeroReflex,stuPID1,v$(STUPID1_VERSION))
#STUPID1_SITE = $(call github,NeroReflex,stuPID1)


#STUPID1_SITE_METHOD = local
#STUPID1_SITE = $(BR2_EXTERNAL_STUPID1_PATH)

STUPID1_DEPENDENCIES = host-rustc

#CARGO_ENV = \
#        cargo build \
#        --release \
#        --manifest-path Cargo.toml \
#        $(STUPID1_CARGO_BUILD_OPTS)
#
#STUPID1_CARGO_BUILD_OPTS = \
#
#
#STUPID1_CARGO_INSTALL_OPTS = \
#	--bin stupid1 \
#	--locked

$(eval $(cargo-package))
