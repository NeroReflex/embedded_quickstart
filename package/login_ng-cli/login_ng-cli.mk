LOGIN_NG_CLI_VERSION = $(LOGIN_NG_VERSION)
LOGIN_NG_CLI_LICENSE = GPL-2.0-or-later
LOGIN_NG_CLI_SITE = $(call github,NeroReflex,login-ng,$(LOGIN_NG_CLI_VERSION))
LOGIN_NG_CLI_DEPENDENCIES = host-rustc
LOGIN_NG_CLI_INSTALL_STAGING = YES
LOGIN_NG_CLI_SUBDIR = login_ng-cli

define LOGIN_NG_CLI_FIX_STAGING_GREETD_CONFIG
	$(SED) 's|agreety --cmd /bin/sh|/usr/bin/login_ng-cli --autologin true|' $(TARGET_DIR)/etc/greetd/config.toml
endef

define LOGIN_NG_CLI_POST_INSTALL
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_EMBEDDED_QUICKSTART_PATH)/package/login_ng-cli/login_ng.pam $(TARGET_DIR)/etc/pam.d/login_ng
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_EMBEDDED_QUICKSTART_PATH)/package/login_ng-cli/login_ng-autologin.pam $(TARGET_DIR)/etc/pam.d/login_ng-autologin
endef

LOGIN_NG_CLI_POST_INSTALL_STAGING_HOOKS += LOGIN_NG_CLI_FIX_STAGING_GREETD_CONFIG

LOGIN_NG_CLI_POST_INSTALL_TARGET_HOOKS += LOGIN_NG_CLI_POST_INSTALL

$(eval $(cargo-package))
