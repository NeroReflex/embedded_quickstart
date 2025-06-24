#!/bin/bash

# Buildroot variables
# $BR2_CONFIG the path to the Buildroot .config file
# $CONFIG_DIR the directory containing the .config file, and therefore the top-level Buildroot Makefile to use (which is correct for both in-tree and out-of-tree builds)
# $HOST_DIR $STAGING_DIR $TARGET_DIR
# $BUILD_DIR the directory where packages are extracted and built 
# $BINARIES_DIR the place where all binary files (aka images) are stored
# $BASE_DIR the base output directory 
# $PARALLEL_JOBS the number of jobs to use when running parallel processes

CURRENT_SCRIPT_DIR="${BASH_SOURCE%/*}"

readonly IMAGE_FILE_PATH="${BINARIES_DIR}/disk_image.img"
if [ ! -f "${IMAGE_FILE_PATH}" ]; then
    echo "Image Disk file not found: creating a new one"
    if ! fallocate -l 1G "${IMAGE_FILE_PATH}"; then
        echo "ERROR: Could not allocate space for target file '${IMAGE_FILE_PATH}'"
        exit -1
    fi
fi

sudo bash "${CURRENT_SCRIPT_DIR}/genimage.sh" $@
