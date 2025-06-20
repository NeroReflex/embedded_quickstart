#!/bin/bash

# Function to handle errors
error_handler() {
    echo "Error occurred at line: $LINENO"
}

# Set the trap to call the error_handler function on ERR
trap 'error_handler' ERR

CURRENT_SCRIPT_DIR="${BASH_SOURCE%/*}"

source "${CURRENT_SCRIPT_DIR}/utils/btrfs_utils.sh"

# $BR2_CONFIG the path to the Buildroot .config file
# $CONFIG_DIR the directory containing the .config file, and therefore the top-level Buildroot Makefile to use (which is correct for both in-tree and out-of-tree builds)
# $HOST_DIR $STAGING_DIR $TARGET_DIR
# $BUILD_DIR the directory where packages are extracted and built 
# $BINARIES_DIR the place where all binary files (aka images) are stored
# $BASE_DIR the base output directory 
# $PARALLEL_JOBS the number of jobs to use when running parallel processes

TARGET_ROOTFS="${BASE_DIR}/rootfs_mnt"
mkdir -p "${BASE_DIR}/rootfs_mnt"

HOME_SUBVOL_NAME="@home"
DEPLOYMENT_SUBVOL_NAME="$1"

if [ -z "$DEPLOYMENT_SUBVOL_NAME" ]; then
    DEPLOYMENT_SUBVOL_NAME="factory"
fi

DEPLOYMENTS_DIR="deployments"
DEPLOYMENTS_DATA_DIR="deployments_data"

#EXTRACTED_ROOTFS_HOST_PATH="${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}/${DEPLOYMENT_SUBVOL_NAME}/"
EXTRACTED_ROOTFS_HOST_PATH="${TARGET_ROOTFS}/"

export PATH="${HOST_DIR}/bin:${PATH}"

# Create the image and mount the rootfs
echo "----------------------------------------------------------"
if [ -f "${BUILD_DIR}/image_path" ] && [ -f "${BUILD_DIR}/image_part" ]; then
    readonly IMAGE_FILE_PATH=$(cat "${BUILD_DIR}/image_path")
    readonly IMAGE_PART_NUMBER=$(cat "${BUILD_DIR}/image_part")

    FS_MODIFY_OUTPUT=$(sudo bash "${CURRENT_SCRIPT_DIR}/utils/modify_image.sh" "$IMAGE_FILE_PATH" "$IMAGE_PART_NUMBER" "$TARGET_ROOTFS")
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

    FS_CREATE_OUTPUT=$(sudo bash "${CURRENT_SCRIPT_DIR}/utils/create_image.sh" "$BTRFS_IMAGE_FILE_PATH" "$TARGET_ROOTFS")
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
ROOTFS_CREATE_OUTPUT=$(sudo bash "${CURRENT_SCRIPT_DIR}/utils/prepare_rootfs.sh" "$TARGET_ROOTFS" "$HOME_SUBVOL_NAME" "$DEPLOYMENT_SUBVOL_NAME" "$DEPLOYMENTS_DIR" "$DEPLOYMENTS_DATA_DIR")
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
readonly partuuid=$("${CURRENT_SCRIPT_DIR}/utils/get_uuid.sh" "${TARGET_ROOTFS}")

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

echo "------------------ PAM Module ----------------------------"

if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth" ]; then
    sudo sed -i '/^[-]auth\s\+sufficient\s\+pam_unix.so/a -auth     sufficient pam_login_ng.so' "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth"
    sudo sed -i '/^[-]account\s\+required\s\+pam_nologin.so/a -account  sufficient pam_login_ng.so' "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth"
    sudo sed -i '/^[-]session\s\+optional\s\+pam_loginuid.so/a -session  optional   pam_login_ng.so' "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth"
fi

echo "----------------------------------------------------------"


# TODO: symlink '/home/user/.config/systemd/user/dbus.service' → '/usr/lib/systemd/user/dbus-broker.service'
# TODO: symlink '/home/user/.config/systemd/user/pipewire-session-manager.service' → '/usr/lib/systemd/user/wireplumber.service'.
# TODO: symlink '/home/user/.config/systemd/user/pipewire.service.wants/wireplumber.service' → '/usr/lib/systemd/user/wireplumber.service'.

if ! sudo btrfs subvol create "${TARGET_ROOTFS}/user_data"; then
    echo "Error setting the autologin user's data subvolume"
    sudo umount "${TARGET_ROOTFS}"
    sudo losetup -D
    exit -1
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

    # [1] following two lines makes systemd believe it's running in degraded mode because even if ro is specified the work directory is being created (and thus that fails)
    #echo "overlay /usr  overlay ro,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,lowerdir=/usr,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null                              0  0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
    #echo "overlay /opt  overlay ro,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,lowerdir=/opt,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null                              0  0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
    echo "overlay /root overlay remount,rw,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,x-systemd.rw-only,lowerdir=/root,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/root_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/root_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null 0  0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
    echo "overlay /etc  overlay remount,rw,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,x-systemd.rw-only,lowerdir=/etc,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/etc_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/etc_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null    0  0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
    echo "overlay /var  overlay remount,rw,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,x-systemd.rw-only,lowerdir=/var,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/var_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/var_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null    0  0" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"

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

    # see [1]
    #echo "#!/bin/sh" | sudo tee "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/remount_overlay.sh"
    #echo "btrfs property set -fts /mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay ro false" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/remount_overlay.sh"
    #echo "btrfs property set -fts /mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay ro false" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/remount_overlay.sh"
    #echo "mount -t overlay -o remount,rw,noatime,lowerdir=/usr,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null overlay /usr" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/remount_overlay.sh"
    #echo "mount -t overlay -o remount,rw,noatime,lowerdir=/opt,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null overlay /opt" | sudo tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/remount_overlay.sh"

    #echo "${DEPLOYMENT_SUBVOL_NAME}" | sudo tee "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdname"

    # prapare the deployment snapshot
    sudo mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/usr/lib/embedded_quickstart"
    echo "${DEPLOYMENT_SUBVOL_NAME}" | sudo tee "${EXTRACTED_ROOTFS_HOST_PATH}/usr/lib/embedded_quickstart/version"

    sudo install -D -m 755 "${CURRENT_SCRIPT_DIR}/install.sh" "${EXTRACTED_ROOTFS_HOST_PATH}/usr/lib/embedded_quickstart/install"

    # Seal the roofs
    echo "Sealing the BTRFS subvolume containing the rootfs"
    sudo btrfs property set -fts "${EXTRACTED_ROOTFS_HOST_PATH}" ro true

    # Generate the deployment snapshot
    sudo btrfs subvolume snapshot -r "${EXTRACTED_ROOTFS_HOST_PATH}" "${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}/${DEPLOYMENT_SUBVOL_NAME}"
    sudo btrfs send "${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}/${DEPLOYMENT_SUBVOL_NAME}" > "${BINARIES_DIR}/${DEPLOYMENT_SUBVOL_NAME}.btrfs"
    cat "${BINARIES_DIR}/${DEPLOYMENT_SUBVOL_NAME}.btrfs" | xz -9e --memory=95% -T0 > "${BINARIES_DIR}/${DEPLOYMENT_SUBVOL_NAME}.btrfs.xz"

    # Change the default subvolid so that the written deployment will get booted
    ROOTFS_DEFAULT_SUBVOLID=$(sudo "${CURRENT_SCRIPT_DIR}/utils/btrfs_get_subvolid.sh" "${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}/${DEPLOYMENT_SUBVOL_NAME}")
    ROOTFS_DEFAULT_SUBVOLID_FETCH_RESULT=$?

    if [ $ROOTFS_DEFAULT_SUBVOLID_FETCH_RESULT -eq 0 ]; then
        if [ "${ROOTFS_DEFAULT_SUBVOLID}" = "5" ]; then
            echo "ERROR: Invalid subvolid for the rootfs subvolume"
            sudo umount "${TARGET_ROOTFS}"
            sudo losetup -D
            exit -1
        elif [ -z "${ROOTFS_DEFAULT_SUBVOLID}" ]; then
            echo "ERROR: Couldn't identify the correct subvolid of the deployment"
            sudo umount "${TARGET_ROOTFS}"
            sudo losetup -D
            exit -1
        fi

        if sudo btrfs subvolume set-default "${ROOTFS_DEFAULT_SUBVOLID}" "${TARGET_ROOTFS}"; then
            echo "Default subvolume for rootfs set to $ROOTFS_DEFAULT_SUBVOLID"
        else
            echo "ERROR: Could not change the default subvolid of '${TARGET_ROOTFS}' to subvolid=$ROOTFS_DEFAULT_SUBVOLID"
            sudo umount "${TARGET_ROOTFS}"
            sudo losetup -D
            exit -1
        fi
    else
        echo "ERROR: Unable to identify the subvolid for the rootfs subvolume"
        sudo umount "${TARGET_ROOTFS}"
        sudo losetup -D
        exit -1
    fi

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
