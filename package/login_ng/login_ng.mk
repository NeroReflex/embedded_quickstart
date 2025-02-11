LOGIN_NG_VERSION = 0.1.6
LOGIN_NG_LICENSE = GPL-2.0
LOGIN_NG_SITE = $(call github,NeroReflex,login-ng,$(LOGIN_NG_VERSION))
LOGIN_NG_DEPENDENCIES = host-rustc
LOGIN_NG_INSTALL_STAGING = YES

define LOGIN_NG_FIX_STAGING_GREETD_CONFIG
	$(SED) 's|agreety --cmd /bin/sh|/usr/bin/login-ng_cli --autologin true|' $(TARGET_DIR)/etc/greetd/config.toml
endef

define LOGIN_NG_POST_INSTALL
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_EMBEDDED_QUICKSTART_PATH)/package/login_ng/login_ng.pam $(TARGET_DIR)/etc/pam.d/login_ng
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_EMBEDDED_QUICKSTART_PATH)/package/login_ng/login_ng-autologin.pam $(TARGET_DIR)/etc/pam.d/login_ng-autologin
endef

LOGIN_NG_POST_INSTALL_STAGING_HOOKS += LOGIN_NG_FIX_STAGING_GREETD_CONFIG

LOGIN_NG_POST_INSTALL_TARGET_HOOKS += LOGIN_NG_POST_INSTALL

$(eval $(cargo-package))
