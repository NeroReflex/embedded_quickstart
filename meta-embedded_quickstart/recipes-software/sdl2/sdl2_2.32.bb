SUMMARY = "SDL2 library"
LICENSE = "Zlib"
LIC_FILES_CHKSUM = " \
    file://LICENSE.txt;md5=cbf0e3161523f9a9315b6b915c5c4457 \
"

DEPENDS += "pkgconfig-native wayland-protocols alsa-lib mesa wayland ibus vulkan-headers "
RDEPENDS += "pkgconfig-native hidapi libusb1"

SRC_URI += "git://github.com/libsdl-org/SDL.git;protocol=https;nobranch=1;branch=release-2.32.x"
SRCREV = "4478ad67d28bb7a586bf352c42c210f36fd03fc0"
S = "${WORKDIR}/git"

EXTRA_OECMAKE=" \
    -D SDL_STATIC=OFF \
    -D SDL_X11=OFF \
    -D SDL_VULKAN=ON \
    -D SDL_WAYLAND=ON \
"

inherit cmake pkgconfig
