inherit cargo

# If this is git based prefer versioned ones if they exist
DEFAULT_PREFERENCE = "-1"

SRC_URI += "git://github.com/NeroReflex/atomrootfsinit.git;protocol=https;nobranch=1;branch=main"
SRCREV = "${PV}"
S = "${WORKDIR}/git"
CARGO_SRC_DIR = ""

SRC_URI += " crate://crates.io/libc/0.2.177 "
SRC_URI[libc-0.2.177.sha256sum] = "2874a2af47a2325c2001a6e6fad9b16a53b802102b528163885171cf92b15976"

LIC_FILES_CHKSUM = " \
    file://LICENSE.md;md5=83ea31b4ebf7c17dcd4f18612a0b1df4 \
"

SUMMARY = "Simple rust software to mount filesystems"
HOMEPAGE = "https://github.com/NeroReflex/atomrootfsinit"
LICENSE = "GPL-2.0-or-later"

# includes this file if it exists but does not fail
# this is useful for anything you may want to override from
# what cargo-bitbake generates.
include atomrootfsinit-${PV}.inc
include atomrootfsinit.inc