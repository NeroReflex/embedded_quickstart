do_compile:append () {
        export RUSTFLAGS="${RUSTFLAGS}"

        bbnote "Using rust targets from ${RUST_TARGET_PATH}"
	bbnote "cargo = $(which ${CARGO})"
	bbnote "${CARGO} build ${CARGO_BUILD_FLAGS} $@"
	"${CARGO}" build ${CARGO_BUILD_FLAGS} "$@"
}

do_install:append () {
    install ${B}/target/${CARGO_TARGET_SUBDIR}/libpam_login_ng.so ${D}/${libdir}/security/pam_login_ng.so

    install -d ${D}/usr/share/dbus-1/system.d/
    install -D -m 644 ${S}/rootfs/usr/share/dbus-1/system.d/org.neroreflex.login_ng_mount.conf \
            ${D}${datadir}/dbus-1/system.d/org.neroreflex.login_ng_mount.conf
    install -D -m 644 ${S}/rootfs/usr/share/dbus-1/system.d/org.neroreflex.login_ng_session.conf \
            ${D}${datadir}/dbus-1/system.d/org.neroreflex.login_ng_session.conf

    install -d ${D}${systemd_unitdir}/system
    install -Dm644 ${S}/rootfs/usr/lib/systemd/system/pam_login_ng.service ${systemd_unitdir}/system/pam_login_ng.service

    install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
    ln -sf ${systemd_unitdir}/system/pam_login_ng.service \
			${D}${sysconfdir}/systemd/system/multi-user.target.wants/pam_login_ng.service
}

FILES:${PN} += "${libdir}/security/pam_login_ng.so ${datadir}/dbus-1/system.d/org.neroreflex.login_ng_mount.conf ${datadir}/dbus-1/system.d/org.neroreflex.login_ng_session.conf ${systemd_unitdir}/system/pam_login_ng.service"
