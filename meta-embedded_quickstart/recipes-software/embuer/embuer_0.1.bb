SUMMARY = "Updater service"
DESCRIPTION = "Updater service with a DBus interface"
LICENSE = "CLOSED"

SRC_URI += "git://github.com/NeroReflex/embuer.git;protocol=https;nobranch=1"
SRCREV = "d50cdcf4f9b506a8f0b4b9cf5ca360e61861a912"
S = "${WORKDIR}/git"

do_install:append () {
    install -d ${D}/${datadir}/embuer
    install -Dm600 ${WORKDIR}/user_autologin_cmd ${D}/${sysconfdir}/autologin/user_autologin_cmd

    install -d ${D}/${systemd_unitdir}/system
    install -Dm644 ${S}/rootfs/usr/lib/systemd/system/embuer.service ${D}/${systemd_unitdir}/system/

    install -d ${D}/${datadir}/dbus-1/system.d
    install -Dm644 ${S}/rootfs/usr/share/dbus-1/system.d/org.neroreflex.embuer.conf ${D}/${datadir}/dbus-1/system.d/

    install -d ${D}/${sysconfdir}/systemd/system/multi-user.target.wants
    ln -sf ${systemd_unitdir}/system/embuer.service \
        ${D}/${sysconfdir}/systemd/system/multi-user.target.wants/embuer.service
}

FILES:${PN} += " \
    ${systemd_unitdir}/system/embuer.service \
    ${datadir}/embuer/ \
"

inherit cargo
include dependencies.inc
