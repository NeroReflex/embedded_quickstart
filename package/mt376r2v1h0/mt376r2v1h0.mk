MT376R2V1H0_VERSION = v0.2
MT376R2V1H0_SITE_METHOD = local
MT376R2V1H0_SITE = ${BR2_EXTERNAL_EMBEDDED_QUICKSTART_PATH}/package/mt376r2v1h0
MT376R2V1H0_INSTALL_TARGET = YES

define MT376R2V1H0_INSTALL_SUSPEND_SYSTEMD
	$(INSTALL) -D -m 755 $(@D)/mt376r2v1h0-resume.sh $(TARGET_DIR)/usr/bin/mt376r2v1h0-resume.sh
	$(INSTALL) -D -m 755 $(@D)/mt376r2v1h0-suspend.sh $(TARGET_DIR)/usr/bin/mt376r2v1h0-suspend.sh
	$(INSTALL) -D -m 644 $(@D)/mt376r2v1h0-suspend.service $(TARGET_DIR)/lib/systemd/system/mt376r2v1h0-suspend.service
endef

define MT376R2V1H0_INSTALL_POWEROFF_SYSTEMD
	$(INSTALL) -D -m 755 $(@D)/mt376r2v1h0-poweroff.sh $(TARGET_DIR)/usr/bin/mt376r2v1h0-poweroff.sh
	$(INSTALL) -D -m 644 $(@D)/mt376r2v1h0-poweroff.service $(TARGET_DIR)/lib/systemd/system/mt376r2v1h0-poweroff.service
endef

define MT376R2V1H0_INSTALL_POWER_USB1_SYSTEMD
	$(INSTALL) -D -m 644 $(@D)/power-usb1.service $(TARGET_DIR)/lib/systemd/system/power-usb1.service
endef

define MT376R2V1H0_INSTALL_POWER_USB2_SYSTEMD
	$(INSTALL) -D -m 644 $(@D)/power-usb2.service $(TARGET_DIR)/lib/systemd/system/power-usb2.service
endef

define MT376R2V1H0_POST_INSTALL
	$(INSTALL) -D -m 644 $(@D)/touch.rules $(TARGET_DIR)/usr/lib/udev/rules.d/90-touch.rules
	$(INSTALL) -D -m 644 $(@D)/usb-power.rules $(TARGET_DIR)/usr/lib/udev/rules.d/90-usb-power.rules
endef

MT376R2V1H0_POST_INSTALL_TARGET_HOOKS += MT376R2V1H0_INSTALL_POWER_USB1_SYSTEMD MT376R2V1H0_INSTALL_POWER_USB2_SYSTEMD
MT376R2V1H0_POST_INSTALL_TARGET_HOOKS += MT376R2V1H0_INSTALL_SUSPEND_SYSTEMD MT376R2V1H0_INSTALL_POWEROFF_SYSTEMD
MT376R2V1H0_POST_INSTALL_TARGET_HOOKS += MT376R2V1H0_POST_INSTALL

$(eval $(generic-package))
