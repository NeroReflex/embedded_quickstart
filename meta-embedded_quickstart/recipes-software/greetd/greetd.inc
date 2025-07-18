do_install:append () {
    install -d ${D}${base_bindir}
    mv ${D}/../build/pgrep ${D}/bin/pgrep
    # greetd.service e un utente greeter (parte di audio e video e seatd) e config.toml in /etc/greetd/config.toml


    install -d ${D}${systemd_unitdir}/greetd
    install -Dm644 ${S}/config.toml ${D}${sysconfdir}/greetd/config.toml

    install -d ${D}${systemd_unitdir}/system
    install -Dm644 ${S}/greetd.service ${D}${systemd_unitdir}/system/seatd.service

    install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
    ln -sf ${systemd_unitdir}/system/seatd.service \
			${D}${sysconfdir}/systemd/system/multi-user.target.wants/seatd.service
}

USERADD_PACKAGES = "greeter"
GROUPADD_PARAM:greeter = "-r seat"
