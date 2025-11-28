SUMMARY = "Autoresize setup service for firstboot"
DESCRIPTION = "Setup autoresize service"

LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = " \
    file://../LICENSE.md;md5=83ea31b4ebf7c17dcd4f18612a0b1df4 \
"

SRC_URI += " \
    file://LICENSE.md \
    file://autoresize-firstboot.sh \
    file://autoresize-setup.service \
"

RDEPENDS:${PN} = "bash btrfs-tools parted"
#DEPENDS = ""

do_install:append () {
    install -d ${D}/${sysconfdir}/autoresize

    install -d ${D}/${systemd_unitdir}/system
    install -Dm644 ${WORKDIR}/autoresize-setup.service ${D}/${systemd_unitdir}/system/autoresize-setup.service

    install -d ${D}/${bindir}
    install -Dm755 ${WORKDIR}/autoresize-firstboot.sh ${D}${bindir}/autoresize-firstboot.sh

    install -d ${D}/${sysconfdir}/systemd/system/multi-user.target.wants
    ln -sf ${systemd_unitdir}/system/autoresize-setup.service \
        ${D}/${sysconfdir}/systemd/system/multi-user.target.wants/autoresize-setup.service
}

FILES:${PN} += " \
    ${bindir}/autoresize-firstboot.sh \
    ${systemd_unitdir}/system/autoresize-setup.service \
"
