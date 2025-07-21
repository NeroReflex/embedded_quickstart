#/bin/bash

set -e

readonly CURRENT_SCRIPT_DIR="${BASH_SOURCE%/*}"
readonly CURRENT_SCRIPT_DIRNAME=$(realpath "$CURRENT_SCRIPT_DIR")

echo "Running from $CURRENT_SCRIPT_DIR"

if [ -z "${MACHINE}" ]; then
    echo "No MACHINE defined. Stop."
    exit 1
fi

source setup-environment.sh && bitbake meta-b2qt-embedded-qbsp

if [ -z "$CURRENT_SCRIPT_DIR" ]; then
    CURRENT_SCRIPT_DIR="."
fi

echo "Running genimage.sh from $CURRENT_SCRIPT_DIRNAME/sources/embedded_quickstart/genimage.sh"
sudo bash "$CURRENT_SCRIPT_DIRNAME/sources/embedded_quickstart/genimage.sh" "$CURRENT_SCRIPT_DIRNAME/build-$MACHINE/tmp/deploy/images/$MACHINE" "factory"

readonly DISK_IMAGE_LINK="$CURRENT_SCRIPT_DIR/disk_image_$MACHINE.img"
echo "Creating symlink ${DISK_IMAGE_LINK}"

rm -f "${DISK_IMAGE_LINK}"
ln -sf "$CURRENT_SCRIPT_DIR/build-$MACHINE/tmp/deploy/images/$MACHINE/disk_image.img" "${DISK_IMAGE_LINK}"
