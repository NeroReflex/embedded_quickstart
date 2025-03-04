# Define the package name and version
IMX_MKIMAGE_POST_NAME := imx-mkimage-post
IMX_MKIMAGE_POST_VERSION := 5.12
IMX_MKIMAGE_POST_SITE = $(call github,NeroReflex,imx-mkimage,$(IMX_MKIMAGE_POST_VERSION))

IMX_MKIMAGE_POST_DEPENDENCIES = \
        imx-atf \
        u-boot \
        host-uboot-tools \
        firmware-imx

IMX_MKIMAGE_POST_MAKE_ENV = \
        $(HOST_MAKE_ENV) \
        BR_BINARIES_DIR=$(BINARIES_DIR)

IMX_MKIMAGE_POST_DEPENDENCIES = \
        $(BR2_MAKE_HOST_DEPENDENCY)
IMX_MKIMAGE_POST_MAKE = $(BR2_MAKE)

# Define the target
define HOST_IMX_MKIMAGE_POST_BUILD_CMDS
    $(shell echo "Copy u-boot compiled binaries into mkimage directory") \
    $(shell cp -v $(BINARIES_DIR)/*.bin $(@D)/$(BR2_EQ_IMX_MKIMAGE_POST_SOC_DIR)/) \
    $(shell echo "Copy firmware files into mkimage directory") \
    $(shell cp -v $(BUILD_DIR)/firmware-imx-*/firmware/ddr/synopsys/*.bin $(@D)/$(BR2_EQ_IMX_MKIMAGE_POST_SOC_DIR)/) \
    $(shell echo "Copy u-boot dtb files into mkimage directory") \
    $(shell find $(BUILD_DIR)/uboot-* -type f -name "*.dtb" -exec cp {} $(@D)/$(BR2_EQ_IMX_MKIMAGE_POST_SOC_DIR)/ \;) \
    $(shell echo "Copy imx-atf into mkimage directory") \
    $(shell cp -v $(TARGET_DIR)/usr/lib/firmware/$(IMX_ATF_FILENAME) $(@D)/$(BR2_EQ_IMX_MKIMAGE_POST_SOC_DIR)/) \
    $(HOST_MAKE_ENV) $(HOST_CONFIGURE_OPTS) MKIMAGE=$(HOST_DIR)/bin/mkimage $(MAKE) -C $(@D) SOC=$(BR2_EQ_IMX_MKIMAGE_POST_SOC) dtbs=$(BR2_EQ_IMX_MKIMAGE_POST_DTBS) $(BR2_EQ_IMX_MKIMAGE_POST_TARGET) \
    $(shell cp -v $(@D)/$(BR2_EQ_IMX_MKIMAGE_POST_SOC_DIR)/flash.bin $(BUILD_DIR)/boot-imx)
endef

# Define the install commands
define IMX_MKIMAGE_POST_INSTALL_CMDS
    $(INSTALL) -D -m 0755 mkimage_imx8 $(HOST_DIR)/usr/bin/mkimage_imx8
endef

# Package definition
$(eval $(host-generic-package))
