# Define the package name and version
IMX_ATF_NAME := imx-atf
IMX_ATF_VERSION := 2.10
IMX_ATF_SITE = $(call github,varigit,imx-atf,lf_v2.10_6.6.52-2.2.0_var01)
# last successful build commit: 3b57a2b9cc3bb103f7ed5d044b1d1a8fcf3a42f6

IMX_ATF_FILENAME=$(BR2_EQ_IMX_ATF_TARGET).bin

IMX_ATF_MAKE_ENV = \
        $(HOST_MAKE_ENV) \
        BR_BINARIES_DIR=$(BINARIES_DIR)

IMX_ATF_DEPENDENCIES = \
        host-kmod \
        $(BR2_MAKE_HOST_DEPENDENCY)
IMX_ATF_MAKE = $(BR2_MAKE)

ATF_BOOT_UART_BASE ?= ""

# Define the target
# TODO: Add SPD=opteed if requested
define IMX_ATF_BUILD_CMDS
    ifeq ($(BR2_EQ_IMX_ATF_TARGET_OPTEE),y)
        $(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) IMX_BOOT_UART_BASE=${ATF_BOOT_UART_BASE} $(MAKE) -C $(@D) PLAT=$(BR2_EQ_IMX_ATF_PLAT) CROSS_COMPILE="$(TARGET_CROSS)" BUILD_BASE=build-optee SPD=opteed $(BR2_EQ_IMX_ATF_TARGET)
    else
        $(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) IMX_BOOT_UART_BASE=${ATF_BOOT_UART_BASE} $(MAKE) -C $(@D) PLAT=$(BR2_EQ_IMX_ATF_PLAT) CROSS_COMPILE="$(TARGET_CROSS)" $(BR2_EQ_IMX_ATF_TARGET)
    endif
endef

# Define the install commands
define IMX_ATF_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/build/$(BR2_EQ_IMX_ATF_PLAT)/release/$(IMX_ATF_FILENAME) $(TARGET_DIR)/usr/lib/firmware/$(IMX_ATF_FILENAME)
endef

# Package definition
$(eval $(generic-package))
