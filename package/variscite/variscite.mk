VARISCITE_VERSION = v0.1
VARISCITE_SITE_METHOD = local
VARISCITE_SITE = ${BR2_EXTERNAL_EMBEDDED_QUICKSTART_PATH}/package/variscite
VARISCITE_INSTALL_TARGET = YES

define VARISCITE_INSTALL_GPIOCHIP
	$(INSTALL) -D -m 644 $(@D)/gpiochip $(TARGET_DIR)/etc/gpiochip
endef

define VARISCITE_INSTALL_WIRELESS
	$(INSTALL) -D -m 755 $(@D)/variscite-wireless $(TARGET_DIR)/etc/wifi/variscite-wireless
endef

define VARISCITE_INSTALL_WIFI
	$(INSTALL) -D -m 755 $(@D)/variscite-wifi $(TARGET_DIR)/etc/wifi/variscite-wifi
endef

define VARISCITE_INSTALL_BLUETOOTH
	$(INSTALL) -D -m 755 $(@D)/variscite-bt $(TARGET_DIR)/etc/bluetooth/variscite-bt
endef

define VARISCITE_INSTALL_WIFI_SYSTEMD
	$(INSTALL) -D -m 644 $(@D)/variscite-wifi.service $(TARGET_DIR)/lib/systemd/system/variscite-wifi.service
endef

define VARISCITE_INSTALL_BLUETOOTH_SYSTEMD
	$(INSTALL) -D -m 644 $(@D)/variscite-bt.service $(TARGET_DIR)/lib/systemd/system/variscite-bt.service
endef

VARISCITE_POST_INSTALL_TARGET_HOOKS += VARISCITE_INSTALL_GPIOCHIP VARISCITE_INSTALL_WIRELESS VARISCITE_INSTALL_WIFI VARISCITE_INSTALL_BLUETOOTH VARISCITE_INSTALL_WIFI_SYSTEMD VARISCITE_INSTALL_BLUETOOTH_SYSTEMD

$(eval $(generic-package))
