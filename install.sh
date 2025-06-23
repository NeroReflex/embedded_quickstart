#!/bin/bash
set -e

# Function to handle errors
error_handler() {
    echo "Error occurred at line: $LINENO"
}

# Set the trap to call the error_handler function on ERR
trap 'error_handler' ERR

CURRENT_SCRIPT_DIR="${BASH_SOURCE%/*}"

CURRENT_DEPLOYMENT_NAME=$(cat "/usr/lib/embedded_quickstart/version")

# Here it is assumed the script is located at /usr/lib/embedded_quickstart
DEPLOYMENT_NAME=$(cat "$CURRENT_SCRIPT_DIR/version")

# this is the place where the subvolid=5 is mounted
MAIN_SUBVOL_PATH="/mnt"

DEPLOYMENTS_DIR="deployments"
DEPLOYMENTS_DATA_DIR="deployments_data"

OLD_SUBVOL_DATA="$MAIN_SUBVOL_PATH/$DEPLOYMENTS_DATA_DIR/$CURRENT_DEPLOYMENT_NAME"
SUBVOL_DATA="$MAIN_SUBVOL_PATH/$DEPLOYMENTS_DATA_DIR/$DEPLOYMENT_NAME"

# here clone the /etc, /var overlay subvolume
btrfs subvol snapshot "${OLD_SUBVOL_DATA}" "${SUBVOL_DATA}"

# here prepare deployments-specific overlays
btrfs subvol create "${SUBVOL_DATA}/usr_overlay"
mkdir "${SUBVOL_DATA}/usr_overlay/upperdir"
mkdir "${SUBVOL_DATA}/usr_overlay/workdir"
btrfs subvol create "${SUBVOL_DATA}/opt_overlay"
mkdir "${SUBVOL_DATA}/opt_overlay/upperdir"
mkdir "${SUBVOL_DATA}/opt_overlay/workdir"
