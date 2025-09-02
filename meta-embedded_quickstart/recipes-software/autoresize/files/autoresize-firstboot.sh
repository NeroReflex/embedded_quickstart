#!/bin/bash

set -e

# Function to handle errors
error_handler() {
    local lineno=$1
    local msg=$2
    echo "Error occurred at line ${lineno}: ${msg}"
    dismantle
}

# Set the trap to call the error_handler function on ERR
trap 'error_handler ${LINENO} "$BASH_COMMAND"' ERR

export TARGET_ROOTFS="/mnt"

if [ "$EUID" -ne 0 ]
    then echo "This script MUST be run as root"
    exit -1
fi

if [ -f "/etc/autoresize" ]; then
    echo "Partition resize already done."
    exit 0
fi

readonly subcmd=$(df -P "${TARGET_ROOTFS}" | tail -n1 | cut -d' ' -f1)

if [ "$subcmd" = "-" ]; then
    echo "WARNING: unrecognised partition, using a fallback..."
    subcmd=$(findmnt --target "${TARGET_ROOTFS}" | grep "/dev" | tail -n1 | cut -d' ' -f2 )
fi

echo "Fetching UUID of partition '${subcmd}'"
readonly possible_uuid=$(lsblk -n -o UUID "${subcmd}")

echo "Fetching partition number of partition '$subcmd'"
readonly part_number=$(echo "${subcmd: -1}")

readonly disk=$(echo "$subcmd" | sed 's/p[0-9]*$//')
readonly filtered_uuid=$(echo "${possible_uuid}" | grep -E '[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}')


# Grow the partition
parted --script "${disk}" resizepart "${part_number}" 100%

# Grow the main btrfs filesystem
btrfs filesystem resize max /mnt

touch "/etc/autoresize"
