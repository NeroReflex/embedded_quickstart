# Define the package name and version
IMX_ATF_NAME := mysoftware
IMX_ATF_VERSION := 1.0
IMX_ATF_SITE = $(call github,nxp-imx,imx-atf,lf-6.12.3-imx943-er1)

# Define the target
define IMX_ATF_BUILD_CMDS
    $(MAKE) PLAT=$(BR2_EQ_IMX_ATF_PLAT) bl31
endef

## Define the install commands
#define IMX_ATF_INSTALL_CMDS
#    $(INSTALL) -D -m 0755 mysoftware $(TARGET_DIR)/usr/bin/mysoftware
#endef

# Package definition
$(eval $(generic-package))
