#!/bin/bash

# Function to handle errors
error_handler() {
    echo "Error occurred at line: $LINENO"
}

# Set the trap to call the error_handler function on ERR
trap 'error_handler' ERR

source "${BASH_SOURCE%/*}/btrfs_utils.sh"

IMAGE_FILE_PATH=${1}
IMAGE_PART_NUMBER=${2}
TARGET_ROOTFS=${3}

LOOPBACK_OUTPUT=$(losetup -P -f --show "${IMAGE_FILE_PATH}")
LOOPBACK_RESULT=$?
if [ $LOOPBACK_RESULT -eq 0 ]; then
    echo "loopback device '$LOOPBACK_OUTPUT'"
else
    echo "ERROR: Cannot setup loop device for file '$IMAGE_FILE_PATH'"
fi

export LOOPBACK_DEV_PART="${LOOPBACK_OUTPUT}p${IMAGE_PART_NUMBER}"
if ! mkfs.btrfs -f "${LOOPBACK_DEV_PART}"; then
    echo "ERROR: Could not format loopback device partition '${LOOPBACK_DEV_PART}'"
    losetup -D
    exit -1
fi

if ! sudo mount -t btrfs -o subvolid=5,compress-force=zstd:15,noatime,rw "${LOOPBACK_DEV_PART}" "${TARGET_ROOTFS}"; then
    echo "ERROR: Could not mount the target loopback partition '${LOOPBACK_DEV_PART}'"
    losetup -D
    exit -1
fi

exit 0
