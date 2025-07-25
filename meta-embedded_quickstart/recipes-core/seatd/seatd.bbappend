do_install:append() {
    if [ "${VIRTUAL-RUNTIME_init_manager}" == "systemd" ]; then
        install -Dm755 ${S}/contrib/systemd/seatd.service ${D}/${systemd_unitdir}/system/seatd.service
        install -d ${D}/${sysconfdir}/systemd/system/multi-user.target.wants
        ln -sf ${systemd_unitdir}/system/seatd.service \
                ${D}${sysconfdir}/systemd/system/multi-user.target.wants/seatd.service
    fi
}

FILES:${PN} += "${systemd_unitdir}/system/seatd.service"
