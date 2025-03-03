# Define the package name and version
IMX_MKIMAGE_NAME := imx-mkimage
IMX_MKIMAGE_VERSION := 1.0
IMX_MKIMAGE_SITE = $(call github,nxp-imx,imx-mkimage,lf-6.12.3-imx943-er1)

IMX_MKIMAGE_MAKE_ENV = \
        $(HOST_MAKE_ENV) \
        BR_BINARIES_DIR=$(BINARIES_DIR)

IMX_MKIMAGE_DEPENDENCIES = \
        $(BR2_MAKE_HOST_DEPENDENCY)
IMX_MKIMAGE_MAKE = $(BR2_MAKE)

# Define the target
define IMX_MKIMAGE_BUILD_CMDS
    $(HOST_MAKE_ENV) $(HOST_CONFIGURE_OPTS) $(MAKE) -C $(@D) SOC=$(BR2_EQ_IMX_MKIMAGE_SOC) $(BR2_EQ_IMX_MKIMAGE_TARGET)
endef

## Define the install commands
#define IMX_MKIMAGE_INSTALL_CMDS
#    $(INSTALL) -D -m 0755 mysoftware $(TARGET_DIR)/usr/bin/mysoftware
#endef

# Package definition
$(eval $(host-generic-package))
