SRC_URI += " \
    file://override.conf \
"

do_install:append () {
    install -d ${D}/${systemd_unitdir}/system/autoresize-setup.service.d/
    install -Dm755 ${WORKDIR}/override.conf ${D}/${systemd_unitdir}/system/autoresize-setup.service.d/override.conf
}

FILES:${PN} += " \
    ${systemd_unitdir}/system/autoresize-setup.service.d/override.conf \
"
