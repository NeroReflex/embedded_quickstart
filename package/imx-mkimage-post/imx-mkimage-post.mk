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
    $(shell cp $(BINARIES_DIR)/*.bin $(@D)/$(BR2_EQ_IMX_MKIMAGE_POST_SOC_DIR)/) \
    $(shell cp $(BUILD_DIR)/firmware-imx-*/firmware/ddr/synopsys/*.bin $(@D)/$(BR2_EQ_IMX_MKIMAGE_POST_SOC_DIR)/) \
    $(shell cp $(TARGET_DIR)/usr/lib/firmware/$(IMX_ATF_FILENAME) $(@D)/$(BR2_EQ_IMX_MKIMAGE_POST_SOC_DIR)/) \
    $(HOST_MAKE_ENV) $(HOST_CONFIGURE_OPTS) MKIMAGE=$(HOST_DIR)/bin/mkimage $(MAKE) -C $(@D) SOC=$(BR2_EQ_IMX_MKIMAGE_POST_SOC) $(BR2_EQ_IMX_MKIMAGE_POST_TARGET)
endef

# Define the install commands
define IMX_MKIMAGE_POST_INSTALL_CMDS
    $(INSTALL) -D -m 0755 mkimage_imx8 $(HOST_DIR)/usr/bin/mkimage_imx8
endef

# Package definition
$(eval $(host-generic-package))
