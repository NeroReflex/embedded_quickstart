PAM_LOGIN_NG_VERSION = 0.7.0
PAM_LOGIN_NG_LICENSE = GPL-2.0-or-later
PAM_LOGIN_NG_SITE = $(call github,NeroReflex,pam_login_ng,$(PAM_LOGIN_NG_VERSION))
PAM_LOGIN_NG_DEPENDENCIES = host-rustc
#PAM_LOGIN_NG_SUBDIR = pam_login_ng
PAM_LOGIN_NG_INSTALL_STAGING = YES

# ls -lah /usr say this: lib64 -> lib
# so install the pam module to /usr/lib/security
#
define PAM_LOGIN_NG_INSTALL_PAM_MODULE
	$(INSTALL) -D -m 755 $(@D)/target/$(RUSTC_TARGET_NAME)/release/libpam_login_ng.so \
		$(TARGET_DIR)/usr/lib/security/pam_login_ng.so
endef

define PAM_LOGIN_NG_INSTALL_DBUS_MOUNT_FILE
	$(INSTALL) -D -m 644 $(@D)/rootfs/usr/share/dbus-1/system.d/org.neroreflex.login_ng_mount.conf \
		$(TARGET_DIR)/usr/share/dbus-1/system.d/org.neroreflex.login_ng_mount.conf
endef

define PAM_LOGIN_NG_INSTALL_DBUS_SESSION_FILE
	$(INSTALL) -D -m 644 $(@D)/rootfs/usr/share/dbus-1/system.d/org.neroreflex.login_ng_session.conf \
		$(TARGET_DIR)/usr/share/dbus-1/system.d/org.neroreflex.login_ng_session.conf
endef

define PAM_LOGIN_NG_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(@D)/rootfs/usr/lib/systemd/system/pam_login_ng.service \
		$(TARGET_DIR)/usr/lib/systemd/system/pam_login_ng.service
endef

PAM_LOGIN_NG_POST_INSTALL_TARGET_HOOKS += PAM_LOGIN_NG_INSTALL_PAM_MODULE PAM_LOGIN_NG_INSTALL_DBUS_MOUNT_FILE PAM_LOGIN_NG_INSTALL_DBUS_SESSION_FILE

$(eval $(cargo-package))
