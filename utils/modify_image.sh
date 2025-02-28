#!/bin/bash

source "${BASH_SOURCE%/*}/btrfs_utils.sh"

IMAGE_FILE_PATH=${1}
IMAGE_PART_NUMBER=${2}
TARGET_ROOTFS=${3}

losetup -P -f --show "${IMAGE_FILE_PATH}"

#if ! sudo mount -o loop "${IMAGE_FILE_PATH}" "${TARGET_ROOTFS}"; then
#    echo "ERROR: Could not mount the target file '${BTRFS_IMAGE_FILE_PATH}'"
#    exit -1
#fi
#
#mkfs.btrfs "${BTRFS_IMAGE_FILE_PATH}"


exit 0