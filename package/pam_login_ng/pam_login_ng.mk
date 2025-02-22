PAM_LOGIN_NG_VERSION = $(LOGIN_NG_VERSION)
PAM_LOGIN_NG_LICENSE = GPL-2.0-or-later
PAM_LOGIN_NG_SITE = $(call github,NeroReflex,login-ng,$(PAM_LOGIN_NG_VERSION))
PAM_LOGIN_NG_DEPENDENCIES = host-rustc
PAM_LOGIN_NG_SUBDIR = pam_login_ng
PAM_LOGIN_NG_INSTALL_STAGING = YES

# ls -lah /usr say this: lib64 -> lib
# so install the pam module to /usr/lib/security
#
define PAM_LOGIN_NG_INSTALL_PAM_MODULE
	$(INSTALL) -D -m 755 $(@D)/target/$(RUSTC_TARGET_NAME)/release/libpam_login_ng.so \
		$(TARGET_DIR)/usr/lib/security/pam_login_ng.so
endef

define PAM_LOGIN_NG_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(@D)/rootfs/usr/lib/systemd/system/pam_login_ng.service \
		$(TARGET_DIR)/usr/lib/systemd/system/pam_login_ng.service
endef

PAM_LOGIN_NG_POST_INSTALL_TARGET_HOOKS += PAM_LOGIN_NG_INSTALL_PAM_MODULE

$(eval $(cargo-package))
