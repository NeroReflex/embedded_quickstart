inherit cargo

# If this is git based prefer versioned ones if they exist
# DEFAULT_PREFERENCE = "-1"

SRC_URI += "git://github.com/NeroReflex/login_ng-session.git;protocol=https;nobranch=1;branch=main"
SRCREV = "${PV}"
S = "${WORKDIR}/git"

SUMMARY = "A manager for user sessions."
HOMEPAGE = "https://github.com/NeroReflex/sessionrunner"

LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = " \
    file://LICENSE.md;md5=83ea31b4ebf7c17dcd4f18612a0b1df4 \
"

do_install:append () {
    install -Dm755 ${S}/rootfs/usr/bin/start-login_ng-session ${D}${bindir}/start-login_ng-session
}

FILES:${PN} += " \
    ${bindir}/start-login_ng-session \
"

# includes this file if it exists but does not fail
# this is useful for anything you may want to override from
# what cargo-bitbake generates.
include ${PN}-${PV}.inc
include ${PN}.inc

# include cargo dependencies
include dependencies.inc
include dependencies_${PV}.inc
