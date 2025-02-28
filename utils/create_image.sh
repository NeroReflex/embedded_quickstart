#!/bin/bash

source "${BASH_SOURCE%/*}/btrfs_utils.sh"

BTRFS_IMAGE_FILE_PATH=${1}
TARGET_ROOTFS=${2}

rm -f "${BTRFS_IMAGE_FILE_PATH}"

if ! fallocate -l 1G "${BTRFS_IMAGE_FILE_PATH}"; then
    echo "ERROR: Could not allocate space for target file '${BTRFS_IMAGE_FILE_PATH}'"
    exit -1
fi

mkfs.btrfs "${BTRFS_IMAGE_FILE_PATH}"

if ! sudo mount -o loop "${BTRFS_IMAGE_FILE_PATH}" "${TARGET_ROOTFS}"; then
    echo "ERROR: Could not mount the target file '${BTRFS_IMAGE_FILE_PATH}'"
    exit -1
fi

exit 0