# Define the package name and version
IMX_MKIMAGE_POST_NAME := imx-mkimage-post
IMX_MKIMAGE_POST_VERSION := 5.10
IMX_MKIMAGE_POST_SITE = $(call github,NeroReflex,imx-mkimage,$(IMX_MKIMAGE_POST_VERSION))

IMX_MKIMAGE_POST_DEPENDENCIES = \
        imx-atf \
        u-boot

IMX_MKIMAGE_POST_MAKE_ENV = \
        $(HOST_MAKE_ENV) \
        BR_BINARIES_DIR=$(BINARIES_DIR)

IMX_MKIMAGE_POST_DEPENDENCIES = \
        $(BR2_MAKE_HOST_DEPENDENCY)
IMX_MKIMAGE_POST_MAKE = $(BR2_MAKE)

# Define the target
define HOST_IMX_MKIMAGE_POST_BUILD_CMDS
    $(shell cp $(BINARIES_DIR)/u-boot-spl.bin $(@D)/$(BR2_EQ_IMX_MKIMAGE_POST_SOC_DIR)/u-boot-spl.bin) \
    $(shell cp $(BINARIES_DIR)/lpddr4_pmu_train_1d_imem.bin $(@D)/$(BR2_EQ_IMX_MKIMAGE_POST_SOC_DIR)/lpddr4_pmu_train_1d_imem.bin) \
    $(shell cp $(HOST_DIR)/usr/lib/firmware/$(IMX_ATF_FILENAME) $(@D)/$(BR2_EQ_IMX_MKIMAGE_POST_SOC_DIR)/$(IMX_ATF_FILENAME)) \
    $(HOST_MAKE_ENV) $(HOST_CONFIGURE_OPTS) $(MAKE) -C $(@D) SOC=$(BR2_EQ_IMX_MKIMAGE_POST_SOC) $(BR2_EQ_IMX_MKIMAGE_POST_TARGET)
endef

## Define the install commands
#define IMX_MKIMAGE_POST_INSTALL_CMDS
#    $(INSTALL) -D -m 0755 mysoftware $(TARGET_DIR)/usr/bin/mysoftware
#endef

# Package definition
$(eval $(host-generic-package))
