LOGIN_NG_VERSION = 0.1.6
LOGIN_NG_LICENSE = GPLv2
LOGIN_NG_SITE = $(call github,NeroReflex,login-ng,$(LOGIN_NG_VERSION))
LOGIN_NG_DEPENDENCIES = host-rustc
LOGIN_NG_INSTALL_STAGING = YES

define LOGIN_NG_FIX_STAGING_GREETD_CONFIG
	$(SED) 's|agreety --cmd /bin/sh|/usr/bin/login-ng_cli|' $(TARGET_DIR)/etc/greetd/config.toml
endef

LOGIN_NG_POST_INSTALL_STAGING_HOOKS += LOGIN_NG_FIX_STAGING_GREETD_CONFIG

$(eval $(cargo-package))
