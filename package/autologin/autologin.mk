AUTOLOGIN_VERSION = v0.1
AUTOLOGIN_SITE_METHOD = local
AUTOLOGIN_SITE = ${BR2_EXTERNAL_EMBEDDED_QUICKSTART_PATH}/package/autologin
AUTOLOGIN_INSTALL_TARGET = YES

define AUTOLOGIN_STORE_USER_PASSWORD
	$(shell echo "${BR2_EQ_AUTOLOGIN_USER}" > "$(BUILD_DIR)/user_autologin_username") \
    $(shell echo "${BR2_EQ_AUTOLOGIN_MAIN_PASSWORD}" > "$(BUILD_DIR)/user_autologin_main_password") \
    $(shell echo "${BR2_EQ_AUTOLOGIN_INTERMEDIATE_PASSWORD}" > "$(BUILD_DIR)/user_autologin_intermediate_key")
endef

AUTOLOGIN_POST_INSTALL_TARGET_HOOKS += AUTOLOGIN_STORE_USER_PASSWORD

$(eval $(generic-package))
