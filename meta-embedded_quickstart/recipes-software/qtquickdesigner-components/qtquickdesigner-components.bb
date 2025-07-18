SUMMARY = "QtQuickDesigner Studio components"
LICENSE = "CLOSED"

inherit qt6-cmake

include recipes-qt/qt6/qt6.inc

DEPENDS += "qtbase qtquick3d qtdeclarative qtdeclarative-native"

SRC_URI += "git://github.com/qt-labs/qtquickdesigner-components.git;protocol=https;nobranch=1;branch=main"
SRCREV = "qds-dev-4.7"
S = "${WORKDIR}/git"
