do_install:append() {
    install -d ${D}/${systemd_unitdir}/system
    install -Dm755 ${S}/contrib/systemd/seatd.service ${D}/${systemd_unitdir}/system/seatd.service
    install -d ${D}/${sysconfdir}/systemd/system/multi-user.target.wants
    ln -sf ${systemd_unitdir}/system/seatd.service \
            ${D}${sysconfdir}/systemd/system/multi-user.target.wants/seatd.service
}

GROUPADD_PARAM:${PN} = “--system seat"

FILES:${PN} += "${systemd_unitdir}/system/seatd.service"
