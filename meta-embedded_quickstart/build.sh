#/bin/bash

set -e

CURRENT_SCRIPT_DIR="${BASH_SOURCE%/*}"

echo "Running from $CURRENT_SCRIPT_DIR"

if [ -z "${MACHINE}" ]; then
    echo "No MACHINE defined. Stop."
    exit 1
fi

source setup-environment.sh && bitbake meta-b2qt-embedded-qbsp

pwd

#sudo bash "$CURRENT_SCRIPT_DIR/../genimage.sh" "$CURRENT_SCRIPT_DIR/../genimage.sh" 