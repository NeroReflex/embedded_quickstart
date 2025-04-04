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
DEPLOYMENT_SUBVOL_NAME="factory"
DEPLOYMENTS_DIR="deployments"
DEPLOYMENTS_DATA_DIR="deployments_data"

EXTRACTED_ROOTFS_HOST_PATH="${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}/${DEPLOYMENT_SUBVOL_NAME}/"

export PATH="${HOST_DIR}/bin:${PATH}"

# Create the image and mount the rootfs
echo "----------------------------------------------------------"
if [ -f "${BUILD_DIR}/image_path" ] && [ -f "${BUILD_DIR}/image_part" ]; then
    readonly IMAGE_FILE_PATH=$(cat "${BUILD_DIR}/image_path")
    readonly IMAGE_PART_NUMBER=$(cat "${BUILD_DIR}/image_part")

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
echo "------------------- root filesystem ----------------------"
ROOTFS_CREATE_OUTPUT=$(sudo bash "${BASH_SOURCE%/*}/utils/prepare_rootfs.sh" "$TARGET_ROOTFS" "$HOME_SUBVOL_NAME" "$DEPLOYMENT_SUBVOL_NAME" "$DEPLOYMENTS_DIR" "$DEPLOYMENTS_DATA_DIR")
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

# Get the UUID of the partition
readonly partuuid=$("${BASH_SOURCE%/*}/utils/get_uuid.sh" "${TARGET_ROOTFS}")

echo "---------------- Filesystem ------------------------------"
if [ -f "${BINARIES_DIR}/rootfs.tar" ]; then
    sudo tar xpf "${BINARIES_DIR}/rootfs.tar" -C "${EXTRACTED_ROOTFS_HOST_PATH}"
else
    echo "No tar rootfs found in '${BINARIES_DIR}/rootfs.tar'"
    sudo umount "${TARGET_ROOTFS}"
    sudo losetup -D
    exit -1
fi

# Avoid failing due to fstab not finding these
sudo mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/usr"
sudo mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/include"
sudo mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/media"
sudo mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/opt"
cho "----------------------------------------------------------"

echo "---------------- login-ng private key --------------------"
login_ng_pkey_file="${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/private_key_pkcs8.pem"
if [ -f "$login_ng_pkey_file" ]; then
    if sudo chmod 600 "$login_ng_pkey_file"; then
        echo "Set permissions 600 to $login_ng_pkey_file"
        if sudo chown 0:0 "$login_ng_pkey_file"; then
            echo "Access to file $login_ng_pkey_file secured"
        else
            echo "Error changing owner to $login_ng_pkey_file"
            sudo umount "${TARGET_ROOTFS}"
            sudo losetup -D
            exit -1
        fi
    else
        echo "Error setting permissions 600 to $login_ng_pkey_file"
        sudo umount "${TARGET_ROOTFS}"
        sudo losetup -D
        exit -1
    fi
fi
echo "----------------------------------------------------------"

if [ -f "${BUILD_DIR}/user_autologin_username" ]; then
    AUTOLOGIN_UID=$(cat "${BUILD_DIR}/user_autologin_uid")
    AUTOLOGIN_GID=$(cat "${BUILD_DIR}/user_autologin_gid")
    AUTOLOGIN_USERNAME=$(cat "${BUILD_DIR}/user_autologin_username")
    AUTOLOGIN_MAIN_PASSWORD=$(cat "${BUILD_DIR}/user_autologin_main_password")
    AUTOLOGIN_INTERMEDIATE_KEY=$(cat "${BUILD_DIR}/user_autologin_intermediate_key")

    AUTOLOGIN_USER_HOME_DIR="${TARGET_ROOTFS}/${HOME_SUBVOL_NAME}/${AUTOLOGIN_USERNAME}"

    sudo mkdir -p "${AUTOLOGIN_USER_HOME_DIR}"

    sudo sed -i '/^[-]auth\s\+sufficient\s\+pam_unix.so/a -auth     sufficient pam_login_ng.so' "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth"
    sudo sed -i '/^[-]account\s\+required\s\+pam_nologin.so/a -account  sufficient pam_login_ng.so' "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth"
    sudo sed -i '/^[-]session\s\+optional\s\+pam_loginuid.so/a -session  optional   pam_login_ng.so' "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth"

    if [ ! -d "${AUTOLOGIN_USER_HOME_DIR}" ]; then
        echo "Could not find user directory '${AUTOLOGIN_USER_HOME_DIR}': at the moment only such directory is supported"
        sudo umount "${TARGET_ROOTFS}"
        sudo losetup -D
        exit -1
    else
        if sudo "${LNG_CTL}" -d "${AUTOLOGIN_USER_HOME_DIR}" -p "${AUTOLOGIN_MAIN_PASSWORD}" setup -i "${AUTOLOGIN_INTERMEDIATE_KEY}"; then
            if sudo "${LNG_CTL}" -d "${AUTOLOGIN_USER_HOME_DIR}" add --name "autologin" --intermediate "${AUTOLOGIN_INTERMEDIATE_KEY}" password --secondary-pw ""; then
                echo "------------------ Autologin User ------------------------"
                echo "Username: ${AUTOLOGIN_USERNAME}"
                echo "Main Password: ${AUTOLOGIN_MAIN_PASSWORD}"
                echo "Intermediate Key: ${AUTOLOGIN_INTERMEDIATE_KEY}"
                echo "----------------------------------------------------------"
                echo ""
                echo ""
            else
                echo "Error setting up the user autologin"
                sudo umount "${TARGET_ROOTFS}"
                sudo losetup -D
                exit -1
            fi

            readonly hashed_password=$(openssl passwd -6 -salt xyz "${AUTOLOGIN_MAIN_PASSWORD}")

            if ! echo "${AUTOLOGIN_USERNAME}:x:${AUTOLOGIN_UID}:${AUTOLOGIN_GID}::/home/${AUTOLOGIN_USERNAME}:/bin/bash" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/passwd"; then
                echo "Error writing the /etc/passwd file"
                sudo umount "${TARGET_ROOTFS}"
                sudo losetup -D
                exit -1
            fi

            if ! echo "${AUTOLOGIN_USERNAME}:${hashed_password}:18000:0:99999:7:-1:-1:" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/shadow"; then
                echo "Error writing the /etc/shadow file"
                sudo umount "${TARGET_ROOTFS}"
                sudo losetup -D
                exit -1
            fi

            if ! echo "${AUTOLOGIN_USERNAME}:x:${AUTOLOGIN_GID}:" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/group"; then
                echo "Error writing the /etc/group file"
                sudo umount "${TARGET_ROOTFS}"
                sudo losetup -D
                exit -1
            fi

            if ! sudo btrfs subvol create "${TARGET_ROOTFS}/.autologin"; then
                echo "Error setting the autologin user's data subvolume"
                sudo umount "${TARGET_ROOTFS}"
                sudo losetup -D
                exit -1
            fi

            if ! sudo "${LNG_CTL}" -d "${AUTOLOGIN_USER_HOME_DIR}" set-home-mount --device "/dev/mmcblk1p1" --fstype "btrfs" --flags "subvol=/.autologin"; then
                echo "Error setting the user home mount"
                sudo umount "${TARGET_ROOTFS}"
                sudo losetup -D
                exit -1
            fi

            # Create the service directory
            if ! sudo mkdir -p "${TARGET_ROOTFS}/etc/login_ng/"; then
                echo "Error in creating ${TARGET_ROOTFS}/etc/login_ng/"
                sudo umount "${TARGET_ROOTFS}"
                sudo losetup -D
                exit -1
            fi

            # Authorize the mount
            AUTOLOGIN_USER_MOUNTS_HASH=$(sudo "${LNG_CTL}" -d "${AUTOLOGIN_USER_HOME_DIR}" inspect | grep 'hash:' | awk '{print $2}')
            AUTOLOGIN_USER_MOUNTS_HASH_GET_RESULT=$?
            if [ $AUTOLOGIN_USER_MOUNTS_HASH_GET_RESULT -eq 0 ]; then
                echo ""
                echo ""
                echo "---------------- Authorized Mounts -----------------------"
                echo '{' | sudo tee "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
                echo '    "authorizations": {' | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
                echo '        "denis": [' | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
                echo "            $AUTOLOGIN_USER_MOUNTS_HASH" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
                echo '        ]' | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
                echo '    }' | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
                echo '}' | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
                echo "----------------------------------------------------------"
                echo ""
                echo ""
                echo "----------------- Autologin Review -----------------------"
                sudo "${LNG_CTL}" -d "${AUTOLOGIN_USER_HOME_DIR}" inspect
                echo "----------------------------------------------------------"

                # Give the service directory correct permissions
                if ! sudo chmod 600 -R "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/"; then
                    echo "Error in setting 700 permissions to ${TARGET_ROOTFS}/etc/login_ng/"
                    sudo umount "${TARGET_ROOTFS}"
                    sudo losetup -D
                    exit -1
                fi
            else
                echo "Error fetching autologin user's mounts"
                sudo umount "${TARGET_ROOTFS}"
                sudo losetup -D
                exit -1
            fi
        else
            echo "Error setting up the user login data"
            sudo umount "${TARGET_ROOTFS}"
            sudo losetup -D
            exit -1
        fi
    fi

    # Assign the user directory to the proper uid and gid
    sudo chown -R "${AUTOLOGIN_UID}":"${AUTOLOGIN_GID}" "${AUTOLOGIN_USER_HOME_DIR}"

    sudo sed -i -e "s|/usr/bin/login_ng-cli --autologin true\"|/usr/bin/login_ng-cli --autologin true --user ${AUTOLOGIN_USERNAME}\"|" "${EXTRACTED_ROOTFS_HOST_PATH}/etc/greetd/config.toml"

    # set the default autologin command
    if [ -f "${BUILD_DIR}/user_autologin_cmd" ]; then
        AUTOLOGIN_CMD=$(cat "${BUILD_DIR}/user_autologin_cmd")
        sudo sed -i -e "s|/usr/bin/login_ng-cli|/usr/bin/login_ng-cli -c ${AUTOLOGIN_CMD}|" "${EXTRACTED_ROOTFS_HOST_PATH}/etc/greetd/config.toml"
    fi
else
    echo "WARNING: No autologin user specified"
fi

sudo mkdir "${EXTRACTED_ROOTFS_HOST_PATH}/base"

echo "------------------- /etc/fstab ---------------------------"
echo "Setting boot partition to PARTUUID: ${partuuid}"

# write /etc/fstab with mountpoints
echo "
LABEL=rootfs  /        btrfs       x-initrd.mount,subvol=/${DEPLOYMENTS_DIR}/${DEPLOYMENT_SUBVOL_NAME},skip_balance,compress=zstd,noatime,rw  0  0
LABEL=rootfs  /home    btrfs       subvol=/${HOME_SUBVOL_NAME},skip_balance,compress=zstd,noatime,rw                                          0  0
LABEL=rootfs  /base    btrfs       x-initrd.mount,subvol=/,skip_balance,x-systemd.requires-mounts-for=/,compress=zstd,noatime,rw              0  0
overlay       /boot    overlay     x-initrd.mount,defaults,x-systemd.requires-mounts-for=/base,lowerdir=/boot,upperdir=/base/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/boot_overlay/upperdir,workdir=/base/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/boot_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off                    0   0
overlay       /usr     overlay     x-initrd.mount,defaults,x-systemd.requires-mounts-for=/base,lowerdir=/usr,upperdir=/base/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay/upperdir,workdir=/base/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off                       0   0
overlay       /opt     overlay     x-initrd.mount,defaults,x-systemd.requires-mounts-for=/base,lowerdir=/opt,upperdir=/base/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay/upperdir,workdir=/base/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off                       0   0
overlay       /media   overlay     x-initrd.mount,defaults,x-systemd.requires-mounts-for=/base,lowerdir=/media,upperdir=/base/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/media_overlay/upperdir,workdir=/base/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/media_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off                 0   0
overlay       /include overlay     x-initrd.mount,defaults,x-systemd.requires-mounts-for=/base,lowerdir=/include,upperdir=/base/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/include_overlay/upperdir,workdir=/base/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/include_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off           0   0
overlay       /root    overlay     x-initrd.mount,defaults,x-systemd.requires-mounts-for=/base,x-systemd.rw-only,lowerdir=/root,upperdir=/base/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/root_overlay/upperdir,workdir=/base/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/root_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off  0   0
overlay       /etc     overlay     x-initrd.mount,defaults,x-systemd.requires-mounts-for=/base,x-systemd.rw-only,lowerdir=/etc,upperdir=/base/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/etc_overlay/upperdir,workdir=/base/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/etc_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off     0   0
overlay       /var     overlay     x-initrd.mount,defaults,x-systemd.requires-mounts-for=/base,x-systemd.rw-only,lowerdir=/var,upperdir=/base/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/var_overlay/upperdir,workdir=/base/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/var_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off     0   0
" | sudo tee "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"

echo "Sealing the BTRFS subvolume containing the rootfs"

# Seal the roofs
sudo btrfs property set -fts "${EXTRACTED_ROOTFS_HOST_PATH}" ro true

echo "----------------------------------------------------------"

# Umount the filesyste and the loopback device
sudo umount "${TARGET_ROOTFS}"
sudo losetup -D

# Write the bootloader to the image
if [ ! -z "${IMAGE_FILE_PATH}" ]; then
    LOOPBACK_OUTPUT=$(sudo losetup -P -f --show "${IMAGE_FILE_PATH}")
    LOOPBACK_RESULT=$?
    if [ $LOOPBACK_RESULT -eq 0 ]; then
        if [ -f "${BUILD_DIR}/boot-imx" ]; then
            echo "Writing the bootloader..."
            if ! sudo dd if="${BUILD_DIR}/boot-imx" of="${LOOPBACK_OUTPUT}" bs=1K seek=33 conv=fsync ; then
                echo "ERROR: Could not write boot-imx to image"
                sudo losetup -D
                exit -1
            fi
        fi
    else
        echo "ERROR: Cannot setup loop device for file '$IMAGE_FILE_PATH'"
        exit -1
    fi

    sudo losetup -D
fi

sync

echo "Image generated successfully!"
