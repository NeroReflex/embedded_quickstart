#!/bin/bash

# Check if a mount directory is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /mount/directory"
    exit 1
fi

MOUNT_DIR="$1"

# Get the device name associated with the mount point
DEVICE=$(df "$MOUNT_DIR" | awk 'NR==2 {print $1}')

# Check if the device was found
if [ -z "$DEVICE" ]; then
    echo "No device found for the mount directory: $MOUNT_DIR"
    exit 1
fi

# Get the UUID of the partition
UUID=$(blkid -s PARTUUID -o value "$DEVICE")

# Check if the UUID was found
if [ -z "$UUID" ]; then
    echo "No PARTUUID found for the device: $DEVICE"
    exit 1
fi

# Output the UUID
echo "The PARTUUID of the disk mounted on $MOUNT_DIR is: $UUID"