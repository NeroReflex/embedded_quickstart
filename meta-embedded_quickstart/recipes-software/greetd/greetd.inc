SRC_URI += " \
    file://greetd.pam \
"

DEPENDS = "libpam seatd systemd"
RDEPENDS:${PN} = "seatd systemd"

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

inherit useradd

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "--system \
                       --shell /bin/false \
                       --groups audio,video,render,seat,input \
                        greeter "

#GROUPADD_PARAM:${PN} = "--system greeter"

FILES:${PN} += " \
    ${sysconfdir}/pam.d/greetd \
    ${systemd_unitdir}/system/greetd.service \
    ${sysconfdir}/greetd/config.toml \
"
