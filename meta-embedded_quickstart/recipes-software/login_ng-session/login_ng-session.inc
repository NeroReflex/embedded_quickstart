do_install:append () {
    install -d ${D}${bindir}/security/
    install -Dm755 ${S}/rootfs/usr/bin/start-login_ng-session ${D}${bindir}/start-login_ng-session
}

FILES:${PN} += "${bindir}/start-login_ng-session"
