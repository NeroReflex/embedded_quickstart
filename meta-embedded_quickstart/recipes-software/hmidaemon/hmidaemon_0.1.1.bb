SUMMARY = "HMI Daemon service"
DESCRIPTION = "The daemon service for the HMI"
LICENSE = "CLOSED"

SRC_URI += " \
    git://github.com/Mitec-Elettronica-Srl/launcher.git;protocol=https;nobranch=1 \
    file://hmidaemon.service \
    file://hmibackup.service \
    file://hmibackup \
"

SRCREV = "${PV}"
S = "${WORKDIR}/git"

RDEPENDS:${PN}:append = " base-files systemd bash btrfs-tools "

FILES:${PN} += " \
    ${systemd_unitdir}/system/hmidaemon.service \
"

inherit cargo

do_install:append () {
    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/hmidaemon.service ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/hmibackup.service ${D}${systemd_unitdir}/system/

    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/hmibackup ${D}${bindir}/
}

inherit systemd

SYSTEMD_AUTO_ENABLE = "enable"
SYSTEMD_SERVICE:${PN} = "hmidaemon.service"

inherit useradd

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "--system \
                       --home /mnt/app_data/current \
                       --shell /bin/false \
                       --user-group \
                        hmidaemon \
                    "

include dependencies.inc
include dependencies_${PV}.inc
