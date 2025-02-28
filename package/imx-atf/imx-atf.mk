# Define the package name and version
IMX_ATF_NAME := imx-atf
IMX_ATF_VERSION := 1.0
IMX_ATF_SITE = $(call github,nxp-imx,imx-atf,lf-6.12.3-imx943-er1)

IMX_ATF_MAKE_ENV = \
        $(HOST_MAKE_ENV) \
        BR_BINARIES_DIR=$(BINARIES_DIR)

IMX_ATF_DEPENDENCIES = \
        host-kmod \
        $(BR2_MAKE_HOST_DEPENDENCY)
IMX_ATF_MAKE = $(BR2_MAKE)

# Define the target
define IMX_ATF_BUILD_CMDS
    $(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) PLAT=$(BR2_EQ_IMX_ATF_PLAT) CROSS_COMPILE="$(TARGET_CROSS)" bl31
endef

## Define the install commands
#define IMX_ATF_INSTALL_CMDS
#    $(INSTALL) -D -m 0755 mysoftware $(TARGET_DIR)/usr/bin/mysoftware
#endef

# Package definition
$(eval $(generic-package))
