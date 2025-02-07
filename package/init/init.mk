INIT_VERSION = 1.0
#STUPID1_SITE = http://example.com/mypackage
#STUPID1_SOURCE = mypackage-$(MYPACKAGE_VERSION).tar.gz
INIT_LICENSE = MIT

INIT_SITE_METHOD = local
INIT_SITE = $(BR2_EXTERNAL_INIT_PATH)
#STUPID1_SITE = $(call github,NeroReflex,stuPID1)

#STUPID1_SITE_METHOD = local
#STUPID1_SITE = $(BR2_EXTERNAL_STUPID1_PATH)

INIT_DEPENDENCIES = host-rustc

#INIT_CARGO_ENV = \
#	cargo build \
#        --release
#        --manifest-path Cargo.toml \
#        $(STUPID1_CARGO_BUILD_OPTS)
#
#INIT_CARGO_BUILD_OPTS = \
#
#
#INIT_CARGO_INSTALL_OPTS = \
#	--bin stupid1 \
#	--locked

$(eval $(cargo-package))
