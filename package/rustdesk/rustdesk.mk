RUSTDESK_VERSION = 1.3.8
RUSTDESK_LICENSE = AGPL-3.0
RUSTDESK_SITE = $(call github,rustdesk,rustdesk,$(RUSTDESK_VERSION))
RUSTDESK_GIT_SUBMODULES = YES
RUSTDESK_DEPENDENCIES = linux-pam \
	host-rustc

$(eval $(cargo-package))
