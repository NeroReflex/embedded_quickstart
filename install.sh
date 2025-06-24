#!/bin/bash
set -e

# Function to handle errors
error_handler() {
    echo "Error occurred at line: $LINENO"
}

# Set the trap to call the error_handler function on ERR
trap 'error_handler' ERR

readonly CURRENT_SCRIPT_DIR="${BASH_SOURCE%/*}"

# this is the place where the subvolid=5 is mounted
readonly MAIN_SUBVOL_PATH="/mnt"

readonly DEPLOYMENTS_DIR="deployments"
readonly DEPLOYMENTS_DATA_DIR="deployments_data"

# Here it is assumed the script is located at /usr/lib/embedded_quickstart
readonly DEPLOYMENT_NAME=$(cat "$CURRENT_SCRIPT_DIR/version")
readonly SUBVOL_DATA="$MAIN_SUBVOL_PATH/$DEPLOYMENTS_DATA_DIR/$DEPLOYMENT_NAME"

if [ -f "/usr/lib/embedded_quickstart/version" ]; then
    readonly CURRENT_DEPLOYMENT_NAME=$(cat "/usr/lib/embedded_quickstart/version")
    readonly OLD_SUBVOL_DATA="$MAIN_SUBVOL_PATH/$DEPLOYMENTS_DATA_DIR/$CURRENT_DEPLOYMENT_NAME"

    # here clone the /etc, /var overlay subvolumes:
    # these are the overlays with modifications that have to be kept
    # across updates.
    btrfs subvol snapshot "${OLD_SUBVOL_DATA}" "${SUBVOL_DATA}"
else
    btrfs subvol create "${SUBVOL_DATA}"
fi

# set /etc and /var overlays as R/W
btrfs property set -fts "${SUBVOL_DATA}" ro false

# here prepare deployments-specific /usr overlay
rmdir "${SUBVOL_DATA}/usr_overlay"
btrfs subvol create "${SUBVOL_DATA}/usr_overlay"
mkdir "${SUBVOL_DATA}/usr_overlay/upperdir"
mkdir "${SUBVOL_DATA}/usr_overlay/workdir"

# here prepare deployments-specific /opt overlay
rmdir "${SUBVOL_DATA}/opt_overlay"
btrfs subvol create "${SUBVOL_DATA}/opt_overlay"
mkdir "${SUBVOL_DATA}/opt_overlay/upperdir"
mkdir "${SUBVOL_DATA}/opt_overlay/workdir"
