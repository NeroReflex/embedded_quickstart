#!/bin/bash

source "${BASH_SOURCE%/*}/btrfs_utils.sh"

BTRFS_IMAGE_FILE_PATH=${1}
TARGET_ROOTFS=${2}
HOME_SUBVOL_NAME=${3}
DEPLOYMENTS_SUBVOL_NAME=${4}
DEPLOYMENTS_DIR=${5}
DEPLOYMENTS_DATA_DIR=${6}

EXTRACTED_ROOTFS_HOST_PATH="${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}/${DEPLOYMENTS_SUBVOL_NAME}/"

rm -f "${BTRFS_IMAGE_FILE_PATH}"

if ! fallocate -l 1G "${BTRFS_IMAGE_FILE_PATH}"; then
    echo "Could not allocate space for target file '${BTRFS_IMAGE_FILE_PATH}'"
    exit -1
fi

mkfs.btrfs "${BTRFS_IMAGE_FILE_PATH}"

mkdir -p "${BASE_DIR}/rootfs_mnt"
if ! sudo mount -o loop "${BTRFS_IMAGE_FILE_PATH}" "${TARGET_ROOTFS}"; then
    echo "Could not mount the target file '${BTRFS_IMAGE_FILE_PATH}'"
    exit -1
fi

btrfs subvolume create "${TARGET_ROOTFS}/${HOME_SUBVOL_NAME}"
mkdir -p "${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}"
btrfs subvolume create "$EXTRACTED_ROOTFS_HOST_PATH"
btrfs subvolume create "${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENTS_SUBVOL_NAME}"
btrfs subvolume create "${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENTS_SUBVOL_NAME}/.etc_workdir"
mkdir -p "${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENTS_SUBVOL_NAME}/etc"
btrfs subvolume create "${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENTS_SUBVOL_NAME}/.var_workdir"
mkdir -p "${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENTS_SUBVOL_NAME}/var"
btrfs subvolume create "${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENTS_SUBVOL_NAME}/.boot_workdir"
btrfs subvolume create "${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENTS_SUBVOL_NAME}/boot"
btrfs subvolume create "${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENTS_SUBVOL_NAME}/.root_workdir"
mkdir -p "${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENTS_SUBVOL_NAME}/root"

ROOTFS_DEFAULT_SUBVOLID=$(btrfs_subvol_get_id "$EXTRACTED_ROOTFS_HOST_PATH")
ROOTFS_DEFAULT_SUBVOLID_FETCH_RESULT=$?

if [ $ROOTFS_DEFAULT_SUBVOLID_FETCH_RESULT -eq 0 ]; then
    if [ "${ROOTFS_DEFAULT_SUBVOLID}" = "5" ]; then
        echo "Invalid subvolid for the rootfs subvolume"
        umount "${TARGET_ROOTFS}"
        exit -1
    elif [ -z "${ROOTFS_DEFAULT_SUBVOLID}" ]; then
        echo "Couldn't identify the correct subvolid of the deployment"
        umount "${TARGET_ROOTFS}"
        exit -1
    fi

    if btrfs subvolume set-default "${ROOTFS_DEFAULT_SUBVOLID}" "${TARGET_ROOTFS}"; then
        echo "Default subvolume for rootfs set to $ROOTFS_DEFAULT_SUBVOLID"
    else
        echo "ERROR: Could not change the default subvolid of '${TARGET_ROOTFS}' to subvolid=$ROOTFS_DEFAULT_SUBVOLID"
        umount "${TARGET_ROOTFS}"
        exit -1
    fi
else
    echo "Unable to identify the subvolid for the rootfs subvolume"
    umount "${TARGET_ROOTFS}"
    exit -1
fi

exit 0