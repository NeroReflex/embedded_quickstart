#!/bin/bash

# Function to handle errors
error_handler() {
    echo "Error occurred at line: $LINENO"
}

# Set the trap to call the error_handler function on ERR
trap 'error_handler' ERR

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

TARGET_ROOTFS="${BASE_DIR}/rootfs_mnt"
mkdir -p "${BASE_DIR}/rootfs_mnt"

HOME_SUBVOL_NAME="@home"
DEPLOYMENTS_SUBVOL_NAME="factory"
DEPLOYMENTS_DIR="deployments"
DEPLOYMENTS_DATA_DIR="deployments_data"

EXTRACTED_ROOTFS_HOST_PATH="${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}/${DEPLOYMENTS_SUBVOL_NAME}/"

# Create the image and mount the rootfs
echo "----------------------------------------------------------"
if [ -f "${BUILD_DIR}/image_path" ] && [ -f "${BUILD_DIR}/image_part" ]; then
    IMAGE_FILE_PATH=$(cat "${BUILD_DIR}/image_path")
    IMAGE_PART_NUMBER=$(cat "${BUILD_DIR}/image_part")

    FS_MODIFY_OUTPUT=$(sudo bash "${BASH_SOURCE%/*}/utils/modify_image.sh" "$IMAGE_FILE_PATH" "$IMAGE_PART_NUMBER" "$TARGET_ROOTFS")
    FS_MODIFY_RESULT=$?

    echo "$FS_MODIFY_OUTPUT"
    if [ $FS_MODIFY_RESULT -eq 0 ]; then
        echo "Image modified: '${IMAGE_FILE_PATH}'"
        echo "Image mounted: '$TARGET_ROOTFS'"
    else
        echo "Unable to modify the image"
        sudo umount "${TARGET_ROOTFS}"
        exit -1
    fi
else
    BTRFS_IMAGE_FILE_PATH="${BINARIES_DIR}/my_btrfs_image.img"

    FS_CREATE_OUTPUT=$(sudo bash "${BASH_SOURCE%/*}/utils/create_image.sh" "$BTRFS_IMAGE_FILE_PATH" "$TARGET_ROOTFS")
    FS_CREATE_RESULT=$?

    echo "$FS_CREATE_OUTPUT"
    if [ $FS_CREATE_RESULT -eq 0 ]; then
        echo "Image created: '${BTRFS_IMAGE_FILE_PATH}'"
        echo "Image mounted: '$TARGET_ROOTFS'"
    else
        echo "Unable to create the image."
        sudo umount "${TARGET_ROOTFS}"
        exit -1
    fi
fi
echo "----------------------------------------------------------"

# Initialize the mounted rootfs
echo "----------------------------------------------------------"
ROOTFS_CREATE_OUTPUT=$(sudo bash "${BASH_SOURCE%/*}/utils/prepare_rootfs.sh" "$TARGET_ROOTFS" "$HOME_SUBVOL_NAME" "$DEPLOYMENTS_SUBVOL_NAME" "$DEPLOYMENTS_DIR" "$DEPLOYMENTS_DATA_DIR")
ROOTFS_CREATE_RESULT=$?

echo "$ROOTFS_CREATE_OUTPUT"
if [ $ROOTFS_CREATE_RESULT -eq 0 ]; then
    echo "rootfs initialized: '${TARGET_ROOTFS}'"
else
    echo "ERROR: Unable to initialize the root filesystem"
    sudo umount "${TARGET_ROOTFS}"
    sudo losetup -D
    exit -1
fi
echo "----------------------------------------------------------"

if [ -f "${BINARIES_DIR}/rootfs.tar" ]; then
    sudo tar xpf "${BINARIES_DIR}/rootfs.tar" -C "${EXTRACTED_ROOTFS_HOST_PATH}"
else
    echo "No tar rootfs found in '${BINARIES_DIR}/rootfs.tar'"
    sudo umount "${TARGET_ROOTFS}"
    sudo losetup -D
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
        sudo losetup -D
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
            sudo losetup -D
            exit -1
        fi
    fi

    sudo sed -i -e "s|/usr/bin/login_ng-cli --autologin true\"|/usr/bin/login_ng-cli --autologin true --user ${AUTOLOGIN_USERNAME}\"|" "${EXTRACTED_ROOTFS_HOST_PATH}/etc/greetd/config.toml"
else
    echo "WARNING: No autologin user specified"
fi

echo "Image generated successfully!"

sudo umount "${TARGET_ROOTFS}"
sudo losetup -D
