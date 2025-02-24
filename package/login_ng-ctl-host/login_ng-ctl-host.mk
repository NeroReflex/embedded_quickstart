HOST_LOGIN_NG_CTL_VERSION = $(LOGIN_NG_VERSION)
HOST_LOGIN_NG_CTL_LICENSE = GPL-2.0-or-later
HOST_LOGIN_NG_CTL_SITE = $(call github,NeroReflex,login-ng,$(HOST_LOGIN_NG_CTL_VERSION))
HOST_LOGIN_NG_CTL_DEPENDENCIES = host-rustc
HOST_LOGIN_NG_CTL_SUBDIR = login_ng-ctl

$(eval $(host-cargo-package))
