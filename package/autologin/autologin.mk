AUTOLOGIN_VERSION = v0.1
AUTOLOGIN_SITE_METHOD = local
AUTOLOGIN_SITE = ${BR2_EXTERNAL_EMBEDDED_QUICKSTART_PATH}/package/autologin
AUTOLOGIN_INSTALL_TARGET = YES

define AUTOLOGIN_STORE_USER_PASSWORD
	$(shell echo "${BR2_EQ_AUTOLOGIN_USER}" > "$(BUILD_DIR)/user_autologin_username") \
    $(shell echo "${BR2_EQ_AUTOLOGIN_MAIN_PASSWORD}" > "$(BUILD_DIR)/user_autologin_main_password") \
    $(shell echo "${BR2_EQ_AUTOLOGIN_INTERMEDIATE_PASSWORD}" > "$(BUILD_DIR)/user_autologin_intermediate_key") \
	$(shell echo "${BR2_EQ_AUTOLOGIN_USER_UID}" > "$(BUILD_DIR)/user_autologin_uid") \
	$(shell echo "${BR2_EQ_AUTOLOGIN_USER_GID}" > "$(BUILD_DIR)/user_autologin_gid")
endef

define AUTOLOGIN_USERS
    ${BR2_EQ_AUTOLOGIN_USER} ${BR2_EQ_AUTOLOGIN_USER_UID} ${BR2_EQ_AUTOLOGIN_USER} ${BR2_EQ_AUTOLOGIN_USER_GID} =${BR2_EQ_AUTOLOGIN_MAIN_PASSWORD} /home/${BR2_EQ_AUTOLOGIN_USER} /bin/sh video Main system user (autologin enabled)
endef

AUTOLOGIN_POST_INSTALL_TARGET_HOOKS += AUTOLOGIN_STORE_USER_PASSWORD

$(eval $(generic-package))
