#!/bin/bash

# $BR2_CONFIG the path to the Buildroot .config file
# $CONFIG_DIR the directory containing the .config file, and therefore the top-level Buildroot Makefile to use (which is correct for both in-tree and out-of-tree builds)
# $HOST_DIR $STAGING_DIR $TARGET_DIR
# $BUILD_DIR the directory where packages are extracted and built 
# $BINARIES_DIR the place where all binary files (aka images) are stored
# $BASE_DIR the base output directory 
# $PARALLEL_JOBS the number of jobs to use when running parallel processes

LNG_CTL="${HOST_DIR}/bin/login_ng-ctl"

if [ ! -f "${LNG_CTL}" ]; then
    echo "Could not find ${LNG_CTL}"
    exit -1
else
    echo "Program ${LNG_CTL} has been found."
fi

BTRFS_IMAGE_FILE_PATH="${BINARIES_DIR}/my_btrfs_image.img"
rm -f "${BTRFS_IMAGE_FILE_PATH}"

if ! fallocate -l 1G "${BTRFS_IMAGE_FILE_PATH}"; then
    echo "Could not allocate space for target file '${BTRFS_IMAGE_FILE_PATH}'"
fi

mkfs.btrfs "${BTRFS_IMAGE_FILE_PATH}"

TARGET_ROOTFS="${BASE_DIR}/rootfs_mnt"
mkdir -p "${BASE_DIR}/rootfs_mnt"
fakeroot mount -o loop "${BTRFS_IMAGE_FILE_PATH}" "${TARGET_ROOTFS}"

if [ -f "${BUILD_DIR}/user_autologin_username" ]; then
    AUTOLOGIN_USERNAME=$(cat "${BUILD_DIR}/user_autologin_username")
    AUTOLOGIN_MAIN_PASSWORD=$(cat "${BUILD_DIR}/user_autologin_main_password")
    AUTOLOGIN_INTERMEDIATE_KEY=$(cat "${BUILD_DIR}/user_autologin_intermediate_key")

    AUTOLOGIN_USER_HOME_DIR="${TARGET_DIR}/home/${AUTOLOGIN_USERNAME}"

    if [ ! -d "${AUTOLOGIN_USER_HOME_DIR}" ]; then
        echo "Could not find user directory '${AUTOLOGIN_USER_HOME_DIR}': at the moment only such directory is supported"
        exit -1
    else
        if $LNG_CTL -d "${AUTOLOGIN_USER_HOME_DIR}" -p "${AUTOLOGIN_MAIN_PASSWORD}" setup -i "${AUTOLOGIN_INTERMEDIATE_KEY}"; then
            echo "Autologin data written correctly"
        else
            echo "Error setting up the autologin data"
            exit -1
        fi
    fi

    fakeroot set -e -i "s|/usr/bin/login_ng-cli --autologin true\"|/usr/bin/login_ng-cli --autologin true --user ${AUTOLOGIN_USERNAME}\"|" "$(TARGET_DIR)/etc/greetd/config.toml"
else
    echo "WARNING: No autologin user specified"
fi