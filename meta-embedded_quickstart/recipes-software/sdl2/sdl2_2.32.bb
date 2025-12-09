SUMMARY = "SDL2 library"
LICENSE = "Zlib"
LIC_FILES_CHKSUM = " \
    file://LICENSE.txt;md5=cbf0e3161523f9a9315b6b915c5c4457 \
"

DEPENDS += "pkgconfig-native"

SRC_URI += "git://github.com/libsdl-org/SDL.git;protocol=https;nobranch=1;branch=release-2.32.x"
SRCREV = "4478ad67d28bb7a586bf352c42c210f36fd03fc0"
S = "${WORKDIR}/git"

inherit cmake
