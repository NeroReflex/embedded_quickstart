SUMMARY = "YUV scaling and conversion"
DESCRIPTION = "Open source project that includes YUV scaling and conversion functionality"

LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=464282cfb405b005b9637f11103a7325"
SRCREV = "0f795672ae3c45f266e61ffad760dc72e69f5cb2"
SRC_URI = "git://chromium.googlesource.com/libyuv/libyuv;protocol=https;branch=main \
           "

S = "${WORKDIR}/git"

# Skip the sanity check about .so not being versioned
INSANE_SKIP_${PN}-dev += "dev-elf"

inherit cmake pkgconfig

#DEPENDS = " nasm-native"
#
#EXTRA_OECMAKE = "-DBUILD_SHARED_LIBS=1 -DENABLE_TESTS=0 \
#                 -DPERL_EXECUTABLE=${HOSTTOOLS_DIR}/perl \
#                "
#CMAKE_VERBOSE = "VERBOSE=1"
#CFLAGS:append:libc-musl = " -D_GNU_SOURCE"
#EXTRA_OECMAKE:append:arm = " -DENABLE_NEON=OFF"

do_install:append() {
    # If library installs /usr/lib/libyuv.so as a real file, replace it with a symlink
    if [ -f ${D}/${libdir}/libyuv.so ] && [ ! -L ${D}/${libdir}/libyuv.so ]; then
        # detect the versioned soname file (common patterns)
        soname_file=$(readelf -a ${D}/${libdir}/libyuv.so 2>/dev/null | sed -n 's/.*SONAME.*$$\$.*\$$$.*/\\1/p' | head -n1)
        if [ -n "${soname_file}" ] && [ -f "${D}/${libdir}/${soname_file}" ]; then
            rm -f ${D}/${libdir}/libyuv.so
            ln -s ${soname_file} ${D}/${libdir}/libyuv.so
        else
            # fallback: if there is a libyuv.so.X or libyuv.so.X.Y, point to the highest match
            target=$(ls ${D}/${libdir}/libyuv.so.* 2>/dev/null | sort -V | tail -n1 || true)
            if [ -n "${target}" ]; then
                target=$(basename ${target})
                rm -f ${D}/${libdir}/libyuv.so
                ln -s ${target} ${D}/${libdir}/libyuv.so
            else
                mv ${D}/${libdir}/libyuv.so ${D}/${libdir}/libyuv.so.1
                ln -s ${D}/${libdir}/libyuv.so.1 ${D}/${libdir}/libyuv.so
            fi
        fi
    fi
}
