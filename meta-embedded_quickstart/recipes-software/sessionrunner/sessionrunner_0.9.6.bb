inherit cargo

# If this is git based prefer versioned ones if they exist
# DEFAULT_PREFERENCE = "-1"

SRC_URI += "git://github.com/NeroReflex/login_ng-session.git;protocol=https;nobranch=1;branch=main"
SRCREV = "${PV}"
S = "${WORKDIR}/git"

RDEPENDS:${PN} = " bash "

SUMMARY = "A manager for user sessions."
HOMEPAGE = "https://github.com/NeroReflex/sessionrunner"

LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = " \
    file://LICENSE.md;md5=83ea31b4ebf7c17dcd4f18612a0b1df4 \
"

do_install:append () {
    install -d ${D}/usr/share/dbus-1/system.d/
    install -D -m 644 ${S}/rootfs/usr/share/dbus-1/system.d/org.neroreflex.sessionrunner.conf \
        ${D}${datadir}/dbus-1/system.d/org.neroreflex.sessionrunner.conf

    install -d ${D}/usr/share/wayland-sessions/
    install -D -m 644 ${S}/rootfs/usr/share/wayland-sessions/sessionrunner.desktop \
        ${D}${datadir}/wayland-sessions/sessionrunner.desktop

    install -d ${D}/usr/share/applications/
    install -D -m 644 ${S}/rootfs/usr/share/applications/org.sessionexec.session-return.desktop \
        ${D}${datadir}/applications/org.sessionexec.session-return.desktop

    install -d ${D}/${libdir}
    install -D -m 755 ${S}/rootfs/usr/lib/os-session-select \
        ${D}/${libdir}/os-session-select

    install -d ${D}/${libdir}/sessionexec
    install -D -m 644 ${S}/rootfs/usr/lib/sessionexec/session-return.sh \
        ${D}/${libdir}/sessionexec/session-return.sh
    install -D -m 644 ${S}/rootfs/usr/lib/sessionexec/plasma-wayland.sh \
        ${D}/${libdir}/sessionexec/plasma-wayland.sh

    install -d ${D}/${libdir}/sessionrunner
    install -D -m 644 ${S}/rootfs/usr/lib/sessionrunner/default.service \
        ${D}/${libdir}/sessionrunner/default.service
    install -D -m 644 ${S}/rootfs/usr/lib/sessionrunner/restart_session.service \
        ${D}/${libdir}/sessionrunner/restart_session.service
}

FILES:${PN} += " \
    ${datadir}/dbus-1/system.d/org.neroreflex.sessionrunner.conf \
    ${libdir}/os-session-select \
    ${libdir}/sessionexec/session-return.sh \
    ${libdir}/sessionexec/plasma-wayland.sh \
    ${datadir}/wayland-sessions/sessionrunner.desktop \
    ${datadir}/applications/org.sessionexec.session-return.desktop \
    ${libdir}/sessionrunner/default.service \
    ${libdir}/sessionrunner/restart_session.service \
"

# includes this file if it exists but does not fail
# this is useful for anything you may want to override from
# what cargo-bitbake generates.
include ${PN}-${PV}.inc
include ${PN}.inc

# include cargo dependencies
include dependencies.inc
include dependencies_${PV}.inc
