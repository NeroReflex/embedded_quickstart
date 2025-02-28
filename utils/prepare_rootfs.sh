#!/bin/bash

# Function to handle errors
error_handler() {
    echo "Error occurred at line: $LINENO"
}

# Set the trap to call the error_handler function on ERR
trap 'error_handler' ERR

source "${BASH_SOURCE%/*}/btrfs_utils.sh"

TARGET_ROOTFS=${1}
HOME_SUBVOL_NAME=${2}
DEPLOYMENTS_SUBVOL_NAME=${3}
DEPLOYMENTS_DIR=${4}
DEPLOYMENTS_DATA_DIR=${5}

EXTRACTED_ROOTFS_HOST_PATH="${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}/${DEPLOYMENTS_SUBVOL_NAME}/"

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
        echo "ERROR: Invalid subvolid for the rootfs subvolume"
        exit -1
    elif [ -z "${ROOTFS_DEFAULT_SUBVOLID}" ]; then
        echo "ERROR: Couldn't identify the correct subvolid of the deployment"
        exit -1
    fi

    if btrfs subvolume set-default "${ROOTFS_DEFAULT_SUBVOLID}" "${TARGET_ROOTFS}"; then
        echo "Default subvolume for rootfs set to $ROOTFS_DEFAULT_SUBVOLID"
    else
        echo "ERROR: Could not change the default subvolid of '${TARGET_ROOTFS}' to subvolid=$ROOTFS_DEFAULT_SUBVOLID"
        exit -1
    fi
else
    echo "ERROR: Unable to identify the subvolid for the rootfs subvolume"
    exit -1
fi

exit 0