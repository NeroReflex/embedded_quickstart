#/bin/bash

set -e

readonly CURRENT_SCRIPT_DIR="${BASH_SOURCE%/*}"
readonly CURRENT_SCRIPT_DIRNAME=$(realpath "$CURRENT_SCRIPT_DIR")

echo "Running from $CURRENT_SCRIPT_DIR"

if [ -z "${MACHINE}" ]; then
    echo "No MACHINE defined. Stop."
    exit 1
fi

if [ -z "${VERSION}" ]; then
    echo "No VERSION defined. Stop."
    exit 1
fi

if [ -z "$CURRENT_SCRIPT_DIR" ]; then
    CURRENT_SCRIPT_DIR="."
fi

if [ ! -d "$CURRENT_SCRIPT_DIR/downloads" ]; then
    echo "Creating symlink to downloads directory"
    mkdir -p "$CURRENT_SCRIPT_DIR/../downloads"
    ln -s "../downloads" "$CURRENT_SCRIPT_DIR/downloads"
fi

# se sposti questa chiama il link simbolico a downloads si spacca.
source setup-environment.sh

if [ ! -z "${BUILD_QBSP}" ]; then
    echo "Building QBSP"
    bitbake meta-b2qt-embedded-qbsp
else
    echo "Building minimal image"
    bitbake b2qt-embedded-qt6-image

    # one can build SDK separately if needed
    if [ ! -z "${BUILD_SDK}" ]; then
        if [ -z "${SDK_MACHINE}" ]; then
            echo "No SDK_MACHINE defined: building default SDK"
        else
            echo "Building SDK for SDK_MACHINE=${SDK_MACHINE}"
        fi
        bitbake meta-toolchain-b2qt-embedded-qt6-sdk
    fi
fi

echo "Running genimage.sh from $CURRENT_SCRIPT_DIRNAME/sources/embedded_quickstart/genimage.sh"
sudo bash "$CURRENT_SCRIPT_DIRNAME/sources/embedded_quickstart/genimage.sh" "$CURRENT_SCRIPT_DIRNAME/build-$MACHINE/tmp/deploy/images/$MACHINE" "${VERSION}"

readonly DISK_IMAGE_LINK="$CURRENT_SCRIPT_DIRNAME/disk_image_$MACHINE.img"

rm -f "${DISK_IMAGE_LINK}"

echo "Creating symlink ${DISK_IMAGE_LINK}"
ln -sf "$CURRENT_SCRIPT_DIRNAME/build-$MACHINE/tmp/deploy/images/$MACHINE/disk_image.img" "${DISK_IMAGE_LINK}"
