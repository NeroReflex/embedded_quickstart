GREETD_VERSION = 0.10.3
GREETD_LICENSE = GPL-3.0
GREETD_SITE = $(call github,kennylevinsen,greetd,$(GREETD_VERSION))
GREETD_DEPENDENCIES = host-rustc
GREETD_SUBDIR = greetd
GREETD_INSTALL_STAGING = YES

define GREETD_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(@D)/greetd.service $(TARGET_DIR)/lib/systemd/system/greetd.service
endef

define GREETD_POST_INSTALL
	$(INSTALL) -D -m 644 $(@D)/config.toml $(TARGET_DIR)/etc/greetd/config.toml
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_EMBEDDED_QUICKSTART_PATH)/package/greetd/greetd.pam $(TARGET_DIR)/etc/pam.d/greetd
endef

define GREETD_USERS
    greeter -1 greeter -1 * - - video Greetd System Daemon
endef

GREETD_POST_INSTALL_TARGET_HOOKS += GREETD_POST_INSTALL

$(eval $(cargo-package))
