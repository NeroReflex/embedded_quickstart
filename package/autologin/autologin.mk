AUTOLOGIN_VERSION = v0.6
AUTOLOGIN_SITE_METHOD = local
AUTOLOGIN_SITE = ${BR2_EXTERNAL_EMBEDDED_QUICKSTART_PATH}/package/autologin
AUTOLOGIN_INSTALL_TARGET = YES

define AUTOLOGIN_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(@D)/autologin-setup.service $(TARGET_DIR)/lib/systemd/system/autologin-setup.service
endef

define AUTOLOGIN_STORE_USER_PASSWORD
	$(shell mkdir -v "$(TARGET_DIR)/etc/autologin/" > /dev/null) \
	$(shell echo "${BR2_EQ_AUTOLOGIN_USER}" > "$(TARGET_DIR)/etc/autologin/user_autologin_username") \
	$(shell chmod 600 "$(TARGET_DIR)/etc/autologin/user_autologin_username") \
    $(shell echo "${BR2_EQ_AUTOLOGIN_MAIN_PASSWORD}" > "$(TARGET_DIR)/etc/autologin/user_autologin_main_password") \
	$(shell chmod 600 "$(TARGET_DIR)/etc/autologin/user_autologin_main_password") \
    $(shell echo "${BR2_EQ_AUTOLOGIN_INTERMEDIATE_PASSWORD}" > "$(TARGET_DIR)/etc/autologin/user_autologin_intermediate_key") \
	$(shell chmod 600 "$(TARGET_DIR)/etc/autologin/user_autologin_intermediate_key") \
	$(shell echo "${BR2_EQ_AUTOLOGIN_USER_UID}" > "$(TARGET_DIR)/etc/autologin/user_autologin_uid") \
	$(shell chmod 600 "$(TARGET_DIR)/etc/autologin/user_autologin_uid") \
	$(shell echo "${BR2_EQ_AUTOLOGIN_USER_GID}" > "$(TARGET_DIR)/etc/autologin/user_autologin_gid") \
	$(shell chmod 600 "$(TARGET_DIR)/etc/autologin/user_autologin_gid") \
	$(shell echo "${BR2_EQ_AUTOLOGIN_CMD}" > "$(TARGET_DIR)/etc/autologin/user_autologin_cmd") \
	$(shell chmod 600 "$(TARGET_DIR)/etc/autologin/user_autologin_cmd")
endef

define AUTOLOGIN_FIRST_BOOT
	$(INSTALL) -D -m 755 $(@D)/autologin-firstboot.sh $(TARGET_DIR)/usr/bin/autologin-firstboot.sh
endef

define AUTOLOGIN_KIOSK_DEFAULT
	$(INSTALL) -D -m 755 $(@D)/kiosk $(TARGET_DIR)/usr/bin/kiosk
endef

define AUTOLOGIN_INSTALL_WESTON_CONF
	$(INSTALL) -D -m 644 $(@D)/weston.ini $(TARGET_DIR)/etc/weston.ini
endef

AUTOLOGIN_POST_INSTALL_TARGET_HOOKS += AUTOLOGIN_INSTALL_INIT_SYSTEMD AUTOLOGIN_FIRST_BOOT AUTOLOGIN_STORE_USER_PASSWORD AUTOLOGIN_KIOSK_DEFAULT AUTOLOGIN_INSTALL_WESTON_CONF

$(eval $(generic-package))
