LOGIN_NG_CTL_VERSION = $(LOGIN_NG_VERSION)
LOGIN_NG_CTL_LICENSE = GPL-2.0-or-later
LOGIN_NG_CTL_SITE = $(call github,NeroReflex,login_ng,$(LOGIN_NG_CTL_VERSION))
LOGIN_NG_CTL_DEPENDENCIES = host-rustc
LOGIN_NG_CTL_INSTALL_STAGING = YES
#LOGIN_NG_CTL_SUBDIR = login_ng-ctl
LOGIN_NG_CTL_CARGO_BUILD_OPTS = --all-features
LOGIN_NG_CTL_CARGO_INSTALL_OPTS = --all-features

define LOGIN_NG_CTL_POST_INSTALL
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_EMBEDDED_QUICKSTART_PATH)/package/login_ng-ctl/login_ng-ctl.pam \
		$(TARGET_DIR)/etc/pam.d/login_ng-ctl
endef

LOGIN_NG_CTL_POST_INSTALL_TARGET_HOOKS += LOGIN_NG_CTL_POST_INSTALL

$(eval $(cargo-package))
$(eval $(host-cargo-package))