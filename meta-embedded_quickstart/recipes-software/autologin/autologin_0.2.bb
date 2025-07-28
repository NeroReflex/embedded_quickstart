SUMMARY = "Autologin setup service for firstboot"
DESCRIPTION = "Setup autologin service"
LICENSE = "CLOSED"

SRC_URI += " \
    file://autologin-firstboot.sh \
    file://autologin-setup.service \
    file://user_autologin_cmd \
    file://user_autologin_gid \
    file://user_autologin_intermediate_key \
    file://user_autologin_main_password \
    file://user_autologin_uid \
    file://user_autologin_username \
"

RDEPENDS:${PN} = "bash greetd loginng pamloginng loginng-session"
#DEPENDS = ""

do_install:append () {
    install -d ${D}/${sysconfdir}/autologin
    install -Dm600 ${WORKDIR}/user_autologin_cmd ${D}/${sysconfdir}/autologin/user_autologin_cmd
    install -Dm600 ${WORKDIR}/user_autologin_gid ${D}/${sysconfdir}/autologin/user_autologin_gid
    install -Dm600 ${WORKDIR}/user_autologin_intermediate_key ${D}/${sysconfdir}/autologin/user_autologin_intermediate_key
    install -Dm600 ${WORKDIR}/user_autologin_main_password ${D}/${sysconfdir}/autologin/user_autologin_main_password
    install -Dm600 ${WORKDIR}/user_autologin_uid ${D}/${sysconfdir}/autologin/user_autologin_uid
    install -Dm600 ${WORKDIR}/user_autologin_username ${D}/${sysconfdir}/autologin/user_autologin_username

    install -d ${D}/${systemd_unitdir}/system
    install -Dm644 ${WORKDIR}/autologin-setup.service ${D}/${systemd_unitdir}/system/autologin-setup.service

    install -d ${D}/${bindir}
    install -Dm755 ${WORKDIR}/autologin-firstboot.sh ${D}${bindir}/autologin-firstboot.sh

    install -d ${D}/${sysconfdir}/systemd/system/multi-user.target.wants
    ln -sf ${systemd_unitdir}/system/autologin-setup.service \
        ${D}/${sysconfdir}/systemd/system/multi-user.target.wants/autologin-setup.service

}

FILES:${PN} += " \
    ${systemd_unitdir}/system/autologin-setup.service \
    ${bindir}/autologin-firstboot.sh \
    ${sysconfdir}/autologin/user_autologin_cmd \
    ${sysconfdir}/autologin/user_autologin_gid \
    ${sysconfdir}/autologin/user_autologin_intermediate_key \
    ${sysconfdir}/autologin/user_autologin_main_password \
    ${sysconfdir}/autologin/user_autologin_uid \
    ${sysconfdir}/autologin/user_autologin_username \
"