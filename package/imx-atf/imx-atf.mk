# Define the package name and version
IMX_ATF_NAME := imx-atf
IMX_ATF_VERSION := 1.0
IMX_ATF_SITE = $(call github,nxp-imx,imx-atf,lf-6.12.3-imx943-er1)

IMX_ATF_FILENAME=$(BR2_EQ_IMX_ATF_TARGET).bin

IMX_ATF_MAKE_ENV = \
        $(HOST_MAKE_ENV) \
        BR_BINARIES_DIR=$(BINARIES_DIR)

IMX_ATF_DEPENDENCIES = \
        host-kmod \
        $(BR2_MAKE_HOST_DEPENDENCY)
IMX_ATF_MAKE = $(BR2_MAKE)

# Define the target
define IMX_ATF_BUILD_CMDS
    $(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) PLAT=$(BR2_EQ_IMX_ATF_PLAT) CROSS_COMPILE="$(TARGET_CROSS)" $(BR2_EQ_IMX_ATF_TARGET)
endef

# Define the install commands
define IMX_ATF_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/build/$(BR2_EQ_IMX_ATF_PLAT)/release/$(IMX_ATF_FILENAME) $(TARGET_DIR)/usr/lib/firmware/$(IMX_ATF_FILENAME)
endef

# Package definition
$(eval $(generic-package))
