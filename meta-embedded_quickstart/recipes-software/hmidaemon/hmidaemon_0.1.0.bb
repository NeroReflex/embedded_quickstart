SUMMARY = "HMI Daemon service"
DESCRIPTION = "The daemon service for the HMI"
LICENSE = "CLOSED"

SRC_URI += " \
    file://hmidaemon.service \
"

RDEPENDS:${PN}:append = " base-files systemd "

FILES:${PN} += " \
    ${systemd_unitdir}/system/hmidaemon.service \
"

do_install:append () {
    install -d ${D}${systemd_unitdir}/system/
    install -m 0755 ${WORKDIR}/hmidaemon.service ${D}${systemd_unitdir}/system/
}

SYSTEMD_SERVICE:${PN} = "hmidaemon.service"

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "--system \
                       --home /mnt/app_data/current \
                       --shell /bin/false \
                       --user-group \
                        hmidaemon \
                    "
