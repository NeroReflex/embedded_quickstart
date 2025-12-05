inherit cargo

# If this is git based prefer versioned ones if they exist
# DEFAULT_PREFERENCE = "-1"

SRC_URI += " \
    git://github.com/kennylevinsen/greetd.git;protocol=https;nobranch=1 \
    file://fix_compilation.patch \
    file://greetd.pam \
"

SRCREV = "${PV}"
S = "${WORKDIR}/git"
CARGO_SRC_DIR = "greetd"

inherit features_check
REQUIRED_DISTRO_FEATURES = "pam"

LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = " \
    file://LICENSE;md5=1ebbd3e34237af26da5dc08a4e440464 \
"

SUMMARY = "greetd"
HOMEPAGE = "https://kl.wtf/projects/greetd"

DEPENDS = " libpam seatd systemd"
RDEPENDS:${PN} = "seatd systemd"

do_install:append () {
    install -d ${D}/${sysconfdir}/pam.d
    install -Dm644 ${WORKDIR}/greetd.pam ${D}/${sysconfdir}/pam.d/greetd

    install -d ${D}/${sysconfdir}/greetd
    install -Dm644 ${S}/config.toml ${D}/${sysconfdir}/greetd/config.toml

    install -d ${D}/${systemd_unitdir}/system
    install -Dm644 ${S}/greetd.service ${D}/${systemd_unitdir}/system/greetd.service

    install -d ${D}/${sysconfdir}/greetd/home_dir/
    touch ${D}/${sysconfdir}/greetd/home_dir/.placeholder
}

SYSTEMD_SERVICE:${PN} = "greetd.service"

inherit useradd

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "--system \
                       --home ${sysconfdir}/greetd/home_dir \
                       --shell /bin/false \
                       --groups audio,video,render,seat,input \
                       --user-group \
                        greeter \
                    "

#GROUPADD_PARAM:${PN} = "--system greeter"

FILES:${PN} += " \
    ${sysconfdir}/pam.d/greetd \
    ${systemd_unitdir}/system/greetd.service \
    ${sysconfdir}/greetd/config.toml \
    ${sysconfdir}/greetd/home_dir/.placeholder \
"

include dependencies.inc
include dependencies_${PV}.inc

# includes this file if it exists but does not fail
# this is useful for anything you may want to override from
# what cargo-bitbake generates.
include greetd-${PV}.inc
include greetd.inc
