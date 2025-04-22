AUTOLOGIN_VERSION = v0.2
AUTOLOGIN_SITE_METHOD = local
AUTOLOGIN_SITE = ${BR2_EXTERNAL_EMBEDDED_QUICKSTART_PATH}/package/autologin
AUTOLOGIN_INSTALL_TARGET = YES

define AUTOLOGIN_STORE_USER_PASSWORD
	$(shell echo "${BR2_EQ_AUTOLOGIN_USER}" > "$(BUILD_DIR)/user_autologin_username") \
    $(shell echo "${BR2_EQ_AUTOLOGIN_MAIN_PASSWORD}" > "$(BUILD_DIR)/user_autologin_main_password") \
    $(shell echo "${BR2_EQ_AUTOLOGIN_INTERMEDIATE_PASSWORD}" > "$(BUILD_DIR)/user_autologin_intermediate_key") \
	$(shell echo "${BR2_EQ_AUTOLOGIN_USER_UID}" > "$(BUILD_DIR)/user_autologin_uid") \
	$(shell echo "${BR2_EQ_AUTOLOGIN_USER_GID}" > "$(BUILD_DIR)/user_autologin_gid") \
	$(shell echo "${BR2_EQ_AUTOLOGIN_CMD}" > "$(BUILD_DIR)/user_autologin_cmd")
endef

define AUTOLOGIN_KIOSK_DEFAULT
	$(INSTALL) -D -m 755 $(@D)/kiosk $(TARGET_DIR)/usr/bin/kiosk
endef

define AUTOLOGIN_INSTALL_WESTON_CONF
	$(INSTALL) -D -m 644 $(@D)/weston.ini $(TARGET_DIR)/etc/weston.ini
endef

define AUTOLOGIN_USERS
    ${BR2_EQ_AUTOLOGIN_USER} ${BR2_EQ_AUTOLOGIN_USER_UID} ${BR2_EQ_AUTOLOGIN_USER} ${BR2_EQ_AUTOLOGIN_USER_GID} =${BR2_EQ_AUTOLOGIN_MAIN_PASSWORD} /home/${BR2_EQ_AUTOLOGIN_USER} /bin/bash seat,render,video Main
endef

AUTOLOGIN_POST_INSTALL_TARGET_HOOKS += AUTOLOGIN_STORE_USER_PASSWORD AUTOLOGIN_KIOSK_DEFAULT AUTOLOGIN_INSTALL_WESTON_CONF

$(eval $(generic-package))
