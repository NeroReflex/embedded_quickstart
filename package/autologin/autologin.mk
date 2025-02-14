AUTOLOGIN_LICENSE = GPL-2.0-or-later
AUTOLOGIN_SITE = $(call github,NeroReflex,login-ng,$(LOGIN_NG_VERSION))
AUTOLOGIN_DEPENDENCIES = host-rustc
AUTOLOGIN_SUBDIR = login_ng-ctl

$(eval $(host-cargo-package))
