SUMMARY = "Updater service"
DESCRIPTION = "Updater service with a DBus interface"
LICENSE = "CLOSED"

SRC_URI += "git://github.com/NeroReflex/embuer.git;protocol=https;nobranch=1"
SRCREV = "9c80c7dd5620def9e03db5703c859631bc071efa"
S = "${WORKDIR}/git"

DEPENDS += " bindgen-cli-native clang-native pkgconfig-native openssl "
RDEPENDS:${PN} += " openssl systemd "

do_install:append () {
    install -d ${D}/${datadir}/embuer

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
    ${datadir}/dbus-1/system.d/org.neroreflex.embuer.conf \
"

inherit cargo
include dependencies.inc
