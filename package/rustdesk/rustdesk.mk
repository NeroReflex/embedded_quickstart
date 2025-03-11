RUSTDESK_VERSION = 1.3.8
RUSTDESK_LICENSE = AGPL-3.0
RUSTDESK_SITE_METHOD = git
RUSTDESK_GIT_SUBMODULES = YES
RUSTDESK_SITE = https://github.com/rustdesk/rustdesk.git
RUSTDESK_DEPENDENCIES = linux-pam \
	host-rustc

$(eval $(cargo-package))
