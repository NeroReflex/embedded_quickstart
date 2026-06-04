#!/bin/bash

# Function to handle errors
error_handler() {
    local lineno=$1
    local msg=$2
    echo "Error occurred at line ${lineno}: ${msg}"
    exit 1
}

# Set the trap to call the error_handler function on ERR
trap 'error_handler ${LINENO} "$BASH_COMMAND"' ERR

source "${BASH_SOURCE%/*}/btrfs_utils.sh"

TARGET_ROOTFS=${1}
HOME_SUBVOL_NAME=${2}
DEPLOYMENT_SUBVOL_NAME=${3}
DEPLOYMENTS_DIR=${4}
DEPLOYMENTS_DATA_DIR=${5}
FACTORY_DATA_DIR=${6}

# Create the home subvolume
btrfs subvolume create "${TARGET_ROOTFS}/${HOME_SUBVOL_NAME}"

# Create subvolumes for deployments and deployment-specific data
btrfs subvolume create "${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}"
btrfs subvolume create "${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}"
btrfs subvolume create "${TARGET_ROOTFS}/${FACTORY_DATA_DIR}"

readonly SUBVOL_DATA="${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}"
btrfs subvolume create "${SUBVOL_DATA}"
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
btrfs subvol create "${SUBVOL_DATA}/opt_overlay"
mkdir "${SUBVOL_DATA}/opt_overlay/upperdir"
mkdir "${SUBVOL_DATA}/opt_overlay/workdir"

# Create read-only app subvolume
btrfs subvolume create "${TARGET_ROOTFS}/app"
echo "" | tee "${TARGET_ROOTFS}/app/hmidaemon.env"
btrfs property set -fts "${TARGET_ROOTFS}/app" ro true
# Create writable app_data subvolumes: mkdir won't work here
btrfs subvolume create "${TARGET_ROOTFS}/app_data"
btrfs subvolume create "${TARGET_ROOTFS}/app_data/current"

btrfs property set -fts "${SUBVOL_DATA}/usr_overlay" ro true
btrfs property set -fts "${SUBVOL_DATA}/opt_overlay" ro true
