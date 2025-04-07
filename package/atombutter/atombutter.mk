ATOMBUTTER_VERSION = 0.1.5
ATOMBUTTER_LICENSE = GPL-2.0-or-later
ATOMBUTTER_SOURCE = $(ATOMBUTTER_VERSION).tar.gz
ATOMBUTTER_SITE = https://github.com/NeroReflex/AtomButter/archive/refs/tags
ATOMBUTTER_DEPENDENCIES = host-rustc
ATOMBUTTER_INSTALL_STAGING = YES
ATOMBUTTER_CARGO_BUILD_OPTS = --all-features
ATOMBUTTER_CARGO_INSTALL_OPTS = --all-features

define ATOMBUTTER_POST_INSTALL
	$(shell ln -sf /usr/bin/atombutter ${TARGET_DIR}/usr/bin/init)
endef

ATOMBUTTER_POST_INSTALL_POST_INSTALL_TARGET_HOOKS += ATOMBUTTER_POST_INSTALL

$(eval $(cargo-package))
