#!/bin/bash

source "${BASH_SOURCE%/*}/utils/btrfs_utils.sh"

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
    exit -1
fi

mkfs.btrfs "${BTRFS_IMAGE_FILE_PATH}"

TARGET_ROOTFS="${BASE_DIR}/rootfs_mnt"
mkdir -p "${BASE_DIR}/rootfs_mnt"
if ! sudo mount -o loop "${BTRFS_IMAGE_FILE_PATH}" "${TARGET_ROOTFS}"; then
    echo "Could not mount the target file '${BTRFS_IMAGE_FILE_PATH}'"
    exit -1
fi

HOME_SUBVOL_NAME="@home"
DEPLOYMENTS_SUBVOL_NAME="factory"
DEPLOYMENTS_DIR="deployments"
DEPLOYMENTS_DATA_DIR="deployments_data"

EXTRACTED_ROOTFS_HOST_PATH="${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}/${DEPLOYMENTS_SUBVOL_NAME}/"

sudo btrfs subvolume create "${TARGET_ROOTFS}/${HOME_SUBVOL_NAME}"
sudo mkdir -p "${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}"
sudo btrfs subvolume create "$EXTRACTED_ROOTFS_HOST_PATH"
sudo mkdir -p "${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENTS_SUBVOL_NAME}/etc"
sudo mkdir -p "${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENTS_SUBVOL_NAME}/var"
sudo mkdir -p "${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENTS_SUBVOL_NAME}/boot"
sudo mkdir -p "${TARGET_ROOTFS}/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENTS_SUBVOL_NAME}/root"

ROOTFS_DEFAULT_SUBVOLID=$(btrfs_subvol_get_id "$EXTRACTED_ROOTFS_HOST_PATH")
ROOTFS_DEFAULT_SUBVOLID_FETCH_RESULT=$?

if [ $ROOTFS_DEFAULT_SUBVOLID_FETCH_RESULT -eq 0 ]; then
    if [ "${ROOTFS_DEFAULT_SUBVOLID}" = "5" ]; then
        echo "Invalid subvolid for the rootfs subvolume"
        sudo umount "${TARGET_ROOTFS}"
        exit -1
    elif [ -z "${ROOTFS_DEFAULT_SUBVOLID}" ]; then
        echo "Couldn't identify the correct subvolid of the deployment"
        sudo umount "${TARGET_ROOTFS}"
        exit -1
    fi

    if ! btrfs subvolume set-default "${ROOTFS_DEFAULT_SUBVOLID}" "${TARGET_ROOTFS}"; then
        echo "Default subvolume for rootfs set to $ROOTFS_DEFAULT_SUBVOLID"
    fi
else
    echo "Unable to identify the subvolid for the rootfs subvolume"
    sudo umount "${TARGET_ROOTFS}"
    exit -1
fi

if [ -f "${BINARIES_DIR}/rootfs.tar" ]; then
    sudo tar xpf "${BINARIES_DIR}/rootfs.tar" -C "${EXTRACTED_ROOTFS_HOST_PATH}"
else
    echo "No tar rootfs found in '${BINARIES_DIR}/rootfs.tar'"
    sudo umount "${TARGET_ROOTFS}"
    exit -1
fi

if [ -f "${BUILD_DIR}/user_autologin_username" ]; then
    AUTOLOGIN_UID=$(cat "${BUILD_DIR}/user_autologin_uid")
    AUTOLOGIN_GID=$(cat "${BUILD_DIR}/user_autologin_gid")
    AUTOLOGIN_USERNAME=$(cat "${BUILD_DIR}/user_autologin_username")
    AUTOLOGIN_MAIN_PASSWORD=$(cat "${BUILD_DIR}/user_autologin_main_password")
    AUTOLOGIN_INTERMEDIATE_KEY=$(cat "${BUILD_DIR}/user_autologin_intermediate_key")

    AUTOLOGIN_USER_HOME_DIR="${TARGET_ROOTFS}/${HOME_SUBVOL_NAME}/${AUTOLOGIN_USERNAME}"

    sudo mkdir -p "${AUTOLOGIN_USER_HOME_DIR}"
    sudo chown -R "${AUTOLOGIN_UID}":"${AUTOLOGIN_GID}" "${AUTOLOGIN_USER_HOME_DIR}"

    if [ ! -d "${AUTOLOGIN_USER_HOME_DIR}" ]; then
        echo "Could not find user directory '${AUTOLOGIN_USER_HOME_DIR}': at the moment only such directory is supported"
        sudo umount "${TARGET_ROOTFS}"
        exit -1
    else
        if $LNG_CTL -d "${AUTOLOGIN_USER_HOME_DIR}" -p "${AUTOLOGIN_MAIN_PASSWORD}" setup -i "${AUTOLOGIN_INTERMEDIATE_KEY}"; then
            echo "----------------------------------------------------------"
            echo "Username: ${AUTOLOGIN_USERNAME}"
            echo "Main Password: ${AUTOLOGIN_MAIN_PASSWORD}"
            echo "Intermediate Key: ${AUTOLOGIN_INTERMEDIATE_KEY}"
            echo "----------------------------------------------------------"
            echo "Autologin data written correctly."
        else
            echo "Error setting up the autologin data"
            sudo umount "${TARGET_ROOTFS}"
            exit -1
        fi
    fi

    sudo sed -i -e "s|/usr/bin/login_ng-cli --autologin true\"|/usr/bin/login_ng-cli --autologin true --user ${AUTOLOGIN_USERNAME}\"|" "${EXTRACTED_ROOTFS_HOST_PATH}/etc/greetd/config.toml"
else
    echo "WARNING: No autologin user specified"
fi

echo "Image generated successfully!"

sudo umount "${TARGET_ROOTFS}"