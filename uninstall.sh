#!/bin/bash
set -e

# Function to handle errors
error_handler() {
    echo "Error occurred at line: $LINENO"
}

# Set the trap to call the error_handler function on ERR
trap 'error_handler' ERR

CURRENT_SCRIPT_DIR="${BASH_SOURCE%/*}"

# Here it is assumed the script is located at /usr/lib/embedded_quickstart
DEPLOYMENT_NAME=$(cat "$CURRENT_SCRIPT_DIR/version")

# this is the place where the subvolid=5 is mounted
MAIN_SUBVOL_PATH="/mnt"

DEPLOYMENTS_DIR="deployments"
DEPLOYMENTS_DATA_DIR="deployments_data"

SUBVOL_DATA="$MAIN_SUBVOL_PATH/$DEPLOYMENTS_DATA_DIR/$DEPLOYMENT_NAME"

# here destroy deployments-specific /usr overlay
btrfs subvol delete "${SUBVOL_DATA}/usr_overlay"

# here destroy deployments-specific /opt overlay
btrfs subvol delete "${SUBVOL_DATA}/opt_overlay"

# here destroy the /etc, /var overlay subvolumes:
# these are the overlays with modifications that have to be kept
# across updates.
btrfs subvol delete "${SUBVOL_DATA}"
