VAR_SOM_IMX8MM_VERSION = v0.3
VAR_SOM_IMX8MM_SITE_METHOD = local
VAR_SOM_IMX8MM_SITE = ${BR2_EXTERNAL_EMBEDDED_QUICKSTART_PATH}/package/var_som_imx8mm
VAR_SOM_IMX8MM_INSTALL_TARGET = YES

define VAR_SOM_IMX8MM_INSTALL_BCM43XX_BT
	$(INSTALL) -D -m 755 $(@D)/bcm43xx-bt $(TARGET_DIR)/etc/bluetooth/variscite-bt.d/bcm43xx-bt
endef

define VAR_SOM_IMX8MM_INSTALL_BCM43XX_WIFI
	$(INSTALL) -D -m 755 $(@D)/bcm43xx-wifi $(TARGET_DIR)/etc/wifi/variscite-wifi.d/bcm43xx-wifi
endef

VAR_SOM_IMX8MM_POST_INSTALL_TARGET_HOOKS += VAR_SOM_IMX8MM_INSTALL_BCM43XX_BT VAR_SOM_IMX8MM_INSTALL_BCM43XX_WIFI

$(eval $(generic-package))
