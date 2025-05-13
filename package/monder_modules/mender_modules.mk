MENDER_MODULES_NAME := mender_modules
MENDER_MODULES_VERSION := 0.1
MENDER_MODULES_SITE = $(call github,NeroReflex,mender_modules,$(MENDER_MODULES_VERSION))

define MENDER_MODULES_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/deployment $(TARGET_DIR)/usr/share/mender/modules/v3/deployment
endef

# Package definition
$(eval $(generic-package))
