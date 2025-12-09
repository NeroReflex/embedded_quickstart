DEPENDS = " systemd"
RDEPENDS:${PN} = "\
    systemd \
    base-files \
"

do_install:append() {
    install -d ${D}/${systemd_unitdir}/system
    install -Dm755 ${S}/contrib/systemd/seatd.service ${D}/${systemd_unitdir}/system/seatd.service
}

inherit useradd

USERADD_PACKAGES = "${PN}"
GROUPADD_PARAM:${PN} = "--system seat"

FILES:${PN} += "${systemd_unitdir}/system/seatd.service"

inherit systemd

SYSTEMD_AUTO_ENABLE = "enable"
SYSTEMD_SERVICE:${PN} = "seatd.service"
