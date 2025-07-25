SUMMARY = "Autologin setup service for firstboot"
DESCRIPTION = "Setup autologin service"
LICENSE = "CLOSED"

SRC_URI += " \
    file://autologin-firstboot.sh \
    file://autologin-setup.service \
"

RDEPENDS:${PN} = "bash greetd loginng pamloginng loginng-session"
#DEPENDS = ""

do_install:append () {
    install -d ${D}${systemd_unitdir}/system
    install -Dm644 ${WORKDIR}/autologin-setup.service ${D}${systemd_unitdir}/system/autologin-setup.service

    install -d ${D}${bindir}
    install -Dm755 ${WORKDIR}/autologin-firstboot.sh ${D}${bindir}/autologin-firstboot.sh

    install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
    ln -sf ${systemd_unitdir}/system/autologin-setup.service \
        ${D}${sysconfdir}/systemd/system/multi-user.target.wants/autologin-setup.service

}

FILES:${PN} += "${systemd_unitdir}/system/autologin-setup.service ${bindir}/autologin-firstboot.sh"