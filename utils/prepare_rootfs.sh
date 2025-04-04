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
DEPLOYMENT_SUBVOL_NAME=${3}
DEPLOYMENTS_DIR=${4}
DEPLOYMENTS_DATA_DIR=${5}

EXTRACTED_ROOTFS_HOST_PATH="${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}/${DEPLOYMENT_SUBVOL_NAME}/"

# Create the home subvolume
btrfs subvolume create "${TARGET_ROOTFS}/${HOME_SUBVOL_NAME}"

# Create directories for deployments and deployment-specific data
mkdir -p "${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}"
mkdir -p "${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}"

# Create the default deployment rootfs snapshot
btrfs subvolume create "$EXTRACTED_ROOTFS_HOST_PATH"

readonly SUBVOL_DATA="${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}"
mkdir -p "${SUBVOL_DATA}/etc_overlay/upperdir"
mkdir -p "${SUBVOL_DATA}/etc_overlay/workdir"
mkdir -p "${SUBVOL_DATA}/var_overlay/upperdir"
mkdir -p "${SUBVOL_DATA}/var_overlay/workdir"
mkdir -p "${SUBVOL_DATA}/root_overlay"
mkdir -p "${SUBVOL_DATA}/root_overlay/upperdir"
mkdir -p "${SUBVOL_DATA}/root_overlay/workdir"
btrfs subvol create "${SUBVOL_DATA}/usr_overlay"
mkdir "${SUBVOL_DATA}/usr_overlay/upperdir"
mkdir "${SUBVOL_DATA}/usr_overlay/workdir"
btrfs subvol create "${SUBVOL_DATA}/boot_overlay"
mkdir "${SUBVOL_DATA}/boot_overlay/upperdir"
mkdir "${SUBVOL_DATA}/boot_overlay/workdir"
btrfs subvol create "${SUBVOL_DATA}/opt_overlay"
mkdir "${SUBVOL_DATA}/opt_overlay/upperdir"
mkdir "${SUBVOL_DATA}/opt_overlay/workdir"
btrfs subvol create "${SUBVOL_DATA}/include_overlay"
mkdir "${SUBVOL_DATA}/include_overlay/upperdir"
mkdir "${SUBVOL_DATA}/include_overlay/workdir"
btrfs subvol create "${SUBVOL_DATA}/media_overlay"
mkdir "${SUBVOL_DATA}/media_overlay/upperdir"
mkdir "${SUBVOL_DATA}/media_overlay/workdir"
btrfs subvol create "${SUBVOL_DATA}/srv_overlay"
mkdir "${SUBVOL_DATA}/srv_overlay/upperdir"
mkdir "${SUBVOL_DATA}/srv_overlay/workdir"
btrfs subvol create "${SUBVOL_DATA}/libexec_overlay"
mkdir "${SUBVOL_DATA}/libexec_overlay/upperdir"
mkdir "${SUBVOL_DATA}/libexec_overlay/workdir"
btrfs subvol create "${SUBVOL_DATA}/mnt_overlay"
mkdir "${SUBVOL_DATA}/mnt_overlay/upperdir"
mkdir "${SUBVOL_DATA}/mnt_overlay/workdir"

btrfs property set -fts "${SUBVOL_DATA}/usr_overlay" ro true
btrfs property set -fts "${SUBVOL_DATA}/opt_overlay" ro true
btrfs property set -fts "${SUBVOL_DATA}/media_overlay" ro true
btrfs property set -fts "${SUBVOL_DATA}/include_overlay" ro true
btrfs property set -fts "${SUBVOL_DATA}/boot_overlay" ro true
btrfs property set -fts "${SUBVOL_DATA}/srv_overlay" ro true
btrfs property set -fts "${SUBVOL_DATA}/libexec_overlay" ro true
btrfs property set -fts "${SUBVOL_DATA}/mnt_overlay" ro true

# Change the default subvolid so that the written deployment will get booted
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
