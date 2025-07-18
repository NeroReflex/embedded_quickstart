do_install:append () {
    install -d ${D}${sysconfdir}/pam.d
    install -Dm644 ${S}/rootfs/etc/pam.d/login_ng ${D}${sysconfdir}/pam.d/login_ng
    install -Dm644 ${S}/rootfs/etc/pam.d/login_ng-autologin ${D}${sysconfdir}/pam.d/login_ng-autologin
    install -Dm644 ${S}/rootfs/etc/pam.d/login_ng-ctl ${D}${sysconfdir}/pam.d/login_ng-ctl
}

FILES:${PN} += "${sysconfdir}/pam.d/login_ng ${sysconfdir}/pam.d/login_ng-autologin"
