PAM_LOGIN_NG_VERSION = $(LOGIN_NG_VERSION)
PAM_LOGIN_NG_LICENSE = GPL-2.0-or-later
PAM_LOGIN_NG_SITE = $(call github,NeroReflex,login-ng,$(PAM_LOGIN_NG_VERSION))
PAM_LOGIN_NG_DEPENDENCIES = host-rustc
PAM_LOGIN_NG_SUBDIR = pam_login_ng
#PAM_LOGIN_NG_INSTALL_STAGING = YES
#
#define PAM_LOGIN_NG_POST_INSTALL
#	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_EMBEDDED_QUICKSTART_PATH)/package/login_ng-ctl/login_ng-ctl.pam $(TARGET_DIR)/etc/pam.d/login_ng-ctl
#endef
#
#PAM_LOGIN_NG_POST_INSTALL_TARGET_HOOKS += PAM_LOGIN_NG_POST_INSTALL
# ls -lah /usr say this: lib64 -> lib
# so install the pam module to /usr/lib/security
#

$(eval $(cargo-package))
