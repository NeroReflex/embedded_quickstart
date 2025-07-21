#/bin/bash

set -e

CURRENT_SCRIPT_DIR="${BASH_SOURCE%/*}"

echo "Running from $CURRENT_SCRIPT_DIR"

if [ -z "${MACHINE}" ]; then
    echo "No MACHINE defined. Stop."
    exit 1
fi

source setup-environment.sh && bitbake meta-b2qt-embedded-qbsp

if [ -z "$CURRENT_SCRIPT_DIR" ]; then
    CURRENT_SCRIPT_DIR="."
fi

dir=$(dirname $pwd)
echo "Running genimage.sh from $dir/sources/embedded_quickstart/genimage.sh"
sudo bash "$CURRENT_SCRIPT_DIR/sources/embedded_quickstart/genimage.sh" "$CURRENT_SCRIPT_DIR/build-$MACHINE/tmp/deploy/images/$MACHINE/" "factory"

rm -f disk_image.img
ln -sf "$CURRENT_SCRIPT_DIR/build-$MACHINE/tmp/deploy/images/$MACHINE/disk_image.img" "disk_image.img"
