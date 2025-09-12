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
