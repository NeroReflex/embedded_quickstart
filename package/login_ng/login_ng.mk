LOGIN_NG_VERSION = 0.1.6
LOGIN_NG_LICENSE = GPLv2
LOGIN_NG_SITE = $(call github,NeroReflex,login-ng,$(LOGIN_NG_VERSION))
LOGIN_NG_DEPENDENCIES = host-rustc

$(eval $(cargo-package))
