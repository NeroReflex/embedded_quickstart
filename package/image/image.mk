IMAGE_VERSION = v0.1
IMAGE_SITE_METHOD = local
IMAGE_SITE = ${BR2_EXTERNAL_EMBEDDED_QUICKSTART_PATH}/package/image
IMAGE_INSTALL_TARGET = YES

define IMAGE_STORE_DATA
	$(shell echo "${BR2_EQ_IMAGE_PATH}" > "$(BUILD_DIR)/image_path") \
    $(shell echo "${BR2_EQ_IMAGE_PART}" > "$(BUILD_DIR)/image_part")
endef

IMAGE_POST_INSTALL_TARGET_HOOKS += IMAGE_STORE_DATA

$(eval $(generic-package))
