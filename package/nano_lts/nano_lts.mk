################################################################################
#
# nano
#
################################################################################

NANO_LTS_VERSION_MAJOR = 7
NANO_LTS_VERSION = $(NANO_LTS_VERSION_MAJOR).2
NANO_LTS_SITE = https://www.nano-editor.org/dist/v$(NANO_LTS_VERSION_MAJOR)
NANO_LTS_SOURCE = nano-$(NANO_LTS_VERSION).tar.xz
NANO_LTS_LICENSE = GPL-3.0+
NANO_LTS_LICENSE_FILES = COPYING
NANO_LTS_DEPENDENCIES = ncurses

ifeq ($(BR2_PACKAGE_NCURSES_WCHAR),y)
NANO_LTS_CONF_ENV += ac_cv_prog_NCURSESW_CONFIG=$(STAGING_DIR)/usr/bin/$(NCURSES_CONFIG_SCRIPTS)
else
NANO_LTS_CONF_ENV += ac_cv_prog_NCURSESW_CONFIG=false
NANO_LTS_MAKE_ENV += CURSES_LIB="-lncurses"
endif

ifeq ($(BR2_PACKAGE_NANO_LTS_TINY),y)
NANO_LTS_CONF_OPTS += \
	--enable-tiny \
	--disable-libmagic \
	--disable-color \
	--disable-nanorc
define NANO_LTS_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 $(@D)/src/nano $(TARGET_DIR)/usr/bin/nano
endef
else
NANO_LTS_CONF_OPTS += --disable-tiny
ifeq ($(BR2_PACKAGE_FILE),y)
NANO_LTS_DEPENDENCIES += file
NANO_LTS_CONF_OPTS += --enable-libmagic --enable-color --enable-nanorc
else
NANO_LTS_CONF_OPTS += --disable-libmagic --disable-color --disable-nanorc
endif # BR2_PACKAGE_FILE
endif # BR2_PACKAGE_NANO_LTS_TINY

$(eval $(autotools-package))
