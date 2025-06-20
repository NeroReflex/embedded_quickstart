MENDER_MODULES_NAME := mender_modules
MENDER_MODULES_VERSION := 0.3
MENDER_MODULES_SITE_METHOD = local
MENDER_MODULES_SITE = ${BR2_EXTERNAL_EMBEDDED_QUICKSTART_PATH}/package/mender_modules
MENDER_MODULES_INSTALL_TARGET = YES

define MENDER_MODULES_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/deployment $(TARGET_DIR)/usr/share/mender/modules/v3/deployment
endef

# Package definition
$(eval $(generic-package))
