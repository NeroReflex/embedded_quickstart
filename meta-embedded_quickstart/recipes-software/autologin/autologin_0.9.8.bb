SUMMARY = "Autologin setup service for firstboot"
DESCRIPTION = "Setup autologin service"

LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = " \
    file://../LICENSE.md;md5=83ea31b4ebf7c17dcd4f18612a0b1df4 \
"

SRC_URI += " \
    file://LICENSE.md \
    file://autologin-firstboot.sh \
    file://autologin-setup.service \
    file://user_autologin_uid \
    file://user_autologin_gid \
    file://user_autologin_intermediate_key \
    file://user_autologin_main_password \
"

RDEPENDS:${PN} = "sudo bash greetd seatd loginng polyauth sessionrunner weston chpasswd"
#DEPENDS = ""

do_install:append () {
    install -d ${D}/${sysconfdir}/autologin
    install -Dm600 ${WORKDIR}/user_autologin_uid ${D}/${sysconfdir}/autologin/user_autologin_uid
    install -Dm600 ${WORKDIR}/user_autologin_gid ${D}/${sysconfdir}/autologin/user_autologin_gid
    install -Dm600 ${WORKDIR}/user_autologin_intermediate_key ${D}/${sysconfdir}/autologin/user_autologin_intermediate_key
    install -Dm600 ${WORKDIR}/user_autologin_main_password ${D}/${sysconfdir}/autologin/user_autologin_main_password

    install -d ${D}/${systemd_unitdir}/system
    install -Dm644 ${WORKDIR}/autologin-setup.service ${D}/${systemd_unitdir}/system/autologin-setup.service

    install -d ${D}/${bindir}
    install -Dm755 ${WORKDIR}/autologin-firstboot.sh ${D}${bindir}/autologin-firstboot.sh
}

FILES:${PN} += " \
    ${bindir}/autologin-firstboot.sh \
    ${systemd_unitdir}/system/autologin-setup.service \
    ${sysconfdir}/autologin/user_autologin_uid \
    ${sysconfdir}/autologin/user_autologin_gid \
    ${sysconfdir}/autologin/user_autologin_intermediate_key \
    ${sysconfdir}/autologin/user_autologin_main_password \
"

inherit systemd

SYSTEMD_AUTO_ENABLE = "enable"
SYSTEMD_SERVICE:${PN} = "autologin-setup.service"
