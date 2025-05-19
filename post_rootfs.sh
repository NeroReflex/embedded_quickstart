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
sudo mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/opt"
sudo mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/root"
sudo mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/etc"
sudo mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/var"
echo "----------------------------------------------------------"

echo "---------------- Boot Process ----------------------------"
if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/stupid1" ]; then
    echo "stuPID1 has been found: setting it as the default init program."
    if [ -L "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init" ]; then
        echo "/sbin/init found: removing default one"
        sudo rm "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init"
    fi

    if ! sudo ln -sf "/usr/bin/stupid1" "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init"; then
        echo "Unable to link /sbin/init -> /usr/bin/stupid1"
        sudo umount "${TARGET_ROOTFS}"
        sudo losetup -D
        exit -1
    fi

    if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/atomrootfsinit" ]; then
        echo "atomrootfsinit has been found: setting it as a second stage after stuPID1."
        if ! sudo ln -sf "/usr/bin/atomrootfsinit" "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/init"; then
            echo "Unable to link /usr/bin/init -> /usr/bin/atomrootfsinit"
            sudo umount "${TARGET_ROOTFS}"
            sudo losetup -D
            exit -1
        fi
    fi
elif [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/atomrootfsinit" ]; then
    if [ -L "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init" ]; then
        echo "/sbin/init found: removing default one"
        sudo rm "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init"
    fi
    
    echo "atomrootfsinit has been found: setting it as first stage."
    if ! sudo ln -sf "/usr/bin/atomrootfsinit" "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init"; then
        echo "Unable to link /sbin/init -> /usr/bin/atomrootfsinit"
        sudo umount "${TARGET_ROOTFS}"
        sudo losetup -D
        exit -1
    fi
else
    echo "Neither stuPID1 nor atomrootfsinit have been found: not touching /sbin/init"
fi

echo "----------------------------------------------------------"

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

    # Because buildroot is bugged and appending more than one additional group in a package breaks every group.
    sudo sed -i "/^seat:/ s/:$/:${AUTOLOGIN_USERNAME}/; /^seat:/ s/:$/:,${AUTOLOGIN_USERNAME}/" "${EXTRACTED_ROOTFS_HOST_PATH}/etc/group"
    sudo sed -i "/^video:/ s/:$/:${AUTOLOGIN_USERNAME}/; /^video:/ s/:$/:,${AUTOLOGIN_USERNAME}/" "${EXTRACTED_ROOTFS_HOST_PATH}/etc/group"
    sudo sed -i "/^render:/ s/:$/:${AUTOLOGIN_USERNAME}/; /^render:/ s/:$/:,${AUTOLOGIN_USERNAME}/" "${EXTRACTED_ROOTFS_HOST_PATH}/etc/group"

    sudo mkdir -p "${AUTOLOGIN_USER_HOME_DIR}"

    if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth" ]; then
        sudo sed -i '/^[-]auth\s\+sufficient\s\+pam_unix.so/a -auth     sufficient pam_login_ng.so' "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth"
        sudo sed -i '/^[-]account\s\+required\s\+pam_nologin.so/a -account  sufficient pam_login_ng.so' "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth"
        sudo sed -i '/^[-]session\s\+optional\s\+pam_loginuid.so/a -session  optional   pam_login_ng.so' "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth"
    fi

    if [ ! -d "${AUTOLOGIN_USER_HOME_DIR}" ]; then
        echo "Could not find user directory '${AUTOLOGIN_USER_HOME_DIR}': at the moment only such directory is supported"
        sudo umount "${TARGET_ROOTFS}"
        sudo losetup -D
        exit -1
    else
        if [ ! -f "${LNG_CTL}" ]; then
            echo "Could not find ${LNG_CTL}"
            exit -1
        fi

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

            if ! sudo btrfs subvol create "${TARGET_ROOTFS}/${AUTOLOGIN_USERNAME}"; then
                echo "Error setting the autologin user's data subvolume"
                sudo umount "${TARGET_ROOTFS}"
                sudo losetup -D
                exit -1
            fi

            sudo mkdir -p "${TARGET_ROOTFS}/${AUTOLOGIN_USERNAME}/upperdir"
            sudo mkdir -p "${TARGET_ROOTFS}/${AUTOLOGIN_USERNAME}/workdir"
            sudo chown ${AUTOLOGIN_UID}:${AUTOLOGIN_GID} "${TARGET_ROOTFS}/${AUTOLOGIN_USERNAME}/upperdir"
            sudo chown ${AUTOLOGIN_UID}:${AUTOLOGIN_GID} "${TARGET_ROOTFS}/${AUTOLOGIN_USERNAME}/workdir"

            if ! sudo "${LNG_CTL}" -d "${AUTOLOGIN_USER_HOME_DIR}" set-home-mount --device "overlay" --fstype "overlay" --flags "lowerdir=/home/user,upperdir=/mnt/$AUTOLOGIN_USERNAME/upperdir,workdir=/mnt/$AUTOLOGIN_USERNAME/workdir,index=off,metacopy=off,xino=off,redirect_dir=off"; then
                echo "Error setting the user home mount"
                sudo umount "${TARGET_ROOTFS}"
                sudo losetup -D
                exit -1
            fi

            # Create the service directory
            if ! sudo mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/"; then
                echo "Error in creating ${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/"
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
                echo "{" | sudo tee "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
                echo "    \"authorizations\": {" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
                echo "        \"${AUTOLOGIN_USERNAME}\": [" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
                echo "            \"${AUTOLOGIN_USER_MOUNTS_HASH}\"" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
                echo "        ]" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
                echo "    }" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
                echo "}" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
                echo "----------------------------------------------------------"
                echo ""
                echo ""
                echo "----------------- Autologin Review -----------------------"
                sudo "${LNG_CTL}" -d "${AUTOLOGIN_USER_HOME_DIR}" inspect
                echo "----------------------------------------------------------"

                # Give the service directory correct permissions
                if ! sudo chmod 600 -R "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/"; then
                    echo "Error in setting 700 permissions to ${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/"
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

    # TODO: symlink '/home/user/.config/systemd/user/dbus.service' → '/usr/lib/systemd/user/dbus-broker.service'
    # TODO: symlink '/home/user/.config/systemd/user/pipewire-session-manager.service' → '/usr/lib/systemd/user/wireplumber.service'.
    # TODO: symlink '/home/user/.config/systemd/user/pipewire.service.wants/wireplumber.service' → '/usr/lib/systemd/user/wireplumber.service'.

else
    echo "WARNING: No autologin user specified"
fi

# if we are creating a mender-compatible deployment create a ro filesystem and mount required things appropriately
if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/mender/modules/v3/deployment" ]; then
    echo "------------------- /etc/fstab ---------------------------"
    echo "Setting boot partition to PARTUUID: ${partuuid}"

    # write /etc/fstab with mountpoints
    if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/lib/systemd/systemd" ]; then
        echo "LABEL=rootfs /home btrfs   rw,noatime,subvol=/${HOME_SUBVOL_NAME},skip_balance,compress=zstd    0  0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
        echo "LABEL=rootfs /mnt btrfs   remount,rw,noatime,x-initrd.mount,subvol=/,skip_balance,compress=zstd 0  0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
    else
        echo "/dev/root /home btrfs   rw,noatime,subvol=/${HOME_SUBVOL_NAME},skip_balance,compress=zstd       0  0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
        echo "/dev/root /mnt btrfs   remount,rw,noatime,x-initrd.mount,subvol=/,skip_balance,compress=zstd    0  0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
    fi
    echo "overlay      /usr  overlay ro,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,lowerdir=/usr,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off                           0  0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
    echo "overlay      /opt  overlay ro,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,lowerdir=/opt,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off                           0  0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
    echo "overlay      /root overlay remount,rw,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,x-systemd.rw-only,lowerdir=/root,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/root_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/root_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off      0  0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
    echo "overlay      /etc  overlay remount,rw,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,x-systemd.rw-only,lowerdir=/etc,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/etc_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/etc_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off 0  0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
    echo "overlay      /var  overlay remount,rw,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,x-systemd.rw-only,lowerdir=/var,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/var_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/var_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off 0  0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"

    # since systemd wants to write /etc/machine-id before mounting things in /etc/fstab and missing /etc/machine-id means dbus-broker breaking
    # if it is available then configure atomrootfsinit to pre-mount /etc and /var
    if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/atomrootfsinit" ]; then
        # kernel auto-mounts /dev
        #echo "dev                   /mnt/dev  devtmpfs rw 0 0" | sudo tee "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdtab"

        echo "dev     /mnt/dev  devtmpfs rw 0 0" | sudo tee "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdtab"
        echo "proc    /mnt/proc proc     rw 0 0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdtab"
        echo "sys     /mnt/sys  sysfs    rw 0 0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdtab"
        echo "rootdev /mnt/mnt  btrfs    rw,noatime,subvol=/,skip_balance,compress=zstd 0 0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdtab"
        echo "overlay /mnt/root overlay  rw,noatime,lowerdir=/mnt/root,upperdir=/mnt/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/root_overlay/upperdir,workdir=/mnt/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/root_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off 0 0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdtab"
        echo "overlay /mnt/etc  overlay  rw,noatime,lowerdir=/mnt/etc,upperdir=/mnt/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/etc_overlay/upperdir,workdir=/mnt/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/etc_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off    0 0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdtab"
        echo "overlay /mnt/var  overlay  rw,noatime,lowerdir=/mnt/var,upperdir=/mnt/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/var_overlay/upperdir,workdir=/mnt/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/var_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off    0 0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdtab"
    fi

    #echo "${DEPLOYMENT_SUBVOL_NAME}" | sudo tee "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdname"

    # Seal the roofs
    echo "Sealing the BTRFS subvolume containing the rootfs"
    sudo btrfs property set -fts "${EXTRACTED_ROOTFS_HOST_PATH}" ro true

    echo "----------------------------------------------------------"
fi

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
