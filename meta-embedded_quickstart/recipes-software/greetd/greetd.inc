SRC_URI += " \
    file://greetd.pam \
"

do_install:append () {
    install -d ${D}/${sysconfdir}/pam.d
    install -Dm644 ${WORKDIR}/greetd.pam ${D}/${sysconfdir}//pam.d/greetd

    install -d ${D}/${sysconfdir}/greetd
    install -Dm644 ${S}/config.toml ${D}/${sysconfdir}/greetd/config.toml

    install -d ${D}/${systemd_unitdir}/system
    install -Dm644 ${S}/greetd.service ${D}/${systemd_unitdir}/system/greetd.service

    install -d ${D}/${sysconfdir}/systemd/system/multi-user.target.wants
    ln -sf ${systemd_unitdir}/system/greetd.service \
			${D}${sysconfdir}/systemd/system/multi-user.target.wants/greetd.service
}

FILES:${PN} += " \
    ${sysconfdir}/pam.d/greetd \
    ${systemd_unitdir}/system/greetd.service \
    ${sysconfdir}/greetd/config.toml \
"

USERADD_PACKAGES = "greeter"
GROUPADD_PARAM:greeter = "-r seat audio video"
