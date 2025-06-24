#!/bin/bash

dismantle() {
    # umount the loopback partition
    if [ ! -z "${MOUNTED_LOOPBACK_PART}" ]; then
        umount "${MOUNTED_LOOPBACK_PART}"
    fi

    # umount the loopback device
    if [ ! -z "${MOUNTED_LOOPBACK}" ]; then
        losetup -d "${MOUNTED_LOOPBACK}"
    fi
}

# Function to handle errors
error_handler() {
    echo "Error occurred at line: $LINENO"
    dismantle
}

# Set the trap to call the error_handler function on ERR
trap 'error_handler' ERR

CURRENT_SCRIPT_DIR="${BASH_SOURCE%/*}"

source "${CURRENT_SCRIPT_DIR}/utils/btrfs_utils.sh"

echo "----------------- Script arguments -----------------------"
# store arguments in a special array 
args=("$@") 
# get number of elements 
ELEMENTS=${#args[@]}

if [ $ELEMENTS -lt 2 ]; then
    echo "Too few arguments provided."
    exit 1
fi

for (( i=0;i<$ELEMENTS;i++)); do 
    echo "$i: ${args[${i}]}" 
done

export BINARIES_DIR="${args[0]}"

echo "----------------------------------------------------------"

# WARNING: this script will work mounting /mnt if not ruunning in buildroot
TARGET_ROOTFS="${BASE_DIR}/mnt"
mkdir -p "${TARGET_ROOTFS}"

readonly HOME_SUBVOL_NAME="@home"

# Read the name of the deployment
DEPLOYMENT_SUBVOL_NAME="${args[1]}"
if [ -z "$DEPLOYMENT_SUBVOL_NAME" ]; then
    DEPLOYMENT_SUBVOL_NAME="factory"
fi

DEPLOYMENTS_DIR="deployments"
DEPLOYMENTS_DATA_DIR="deployments_data"

readonly EXTRACTED_ROOTFS_HOST_PATH="${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}/${DEPLOYMENT_SUBVOL_NAME}/"
#readonly EXTRACTED_ROOTFS_HOST_PATH="${TARGET_ROOTFS}/"

export PATH="${HOST_DIR}/bin:${PATH}"

# Create the image and mount the rootfs
echo "----------------- Creating Image -------------------------"
echo "Deployment name: $DEPLOYMENT_SUBVOL_NAME"
echo "----------------------------------------------------------"

# Create the image and mount the rootfs
echo "----------------- Creating Image -------------------------"
readonly IMAGE_FILE_PATH="${BINARIES_DIR}/disk_image.img"

if [ ! -f "${IMAGE_FILE_PATH}" ]; then
    echo "Image Disk file not found: creating a new one"
    if ! fallocate -l 1G "${IMAGE_FILE_PATH}"; then
        echo "ERROR: Could not allocate space for target file '${IMAGE_FILE_PATH}'"
        exit -1
    fi
fi

readonly LOOPBACK_OUTPUT=$(losetup -P -f --show "${IMAGE_FILE_PATH}")
readonly LOOPBACK_RESULT=$?
if [ $LOOPBACK_RESULT -eq 0 ]; then
    echo "loopback device '$LOOPBACK_OUTPUT'"
    export MOUNTED_LOOPBACK="${LOOPBACK_OUTPUT}"
else
    echo "ERROR: Cannot setup loop device for file '$IMAGE_FILE_PATH'"
    exit -1
fi

if [ -f "${BINARIES_DIR}/boot-imx" ]; then
    parted -s "${LOOPBACK_OUTPUT}" mklabel msdos
    parted -s "${LOOPBACK_OUTPUT}" --script mkpart primary btrfs 8MiB 100%
    echo "Writing the bootloader..."
    if ! dd if="${BINARIES_DIR}/boot-imx" of="${LOOPBACK_OUTPUT}" bs=1K seek=33 conv=fsync ; then
        echo "ERROR: Could not write boot-imx to image"
        dismantle
        exit -1
    fi
    export IMAGE_PART_NUMBER="1"
else
    echo "Unsupported hardware."
    dismantle
    exit -1
fi

export LOOPBACK_DEV_PART="${LOOPBACK_OUTPUT}p${IMAGE_PART_NUMBER}"
if ! mkfs.btrfs -f "${LOOPBACK_DEV_PART}" -L rootfs; then
    echo "ERROR: Could not format loopback device partition '${LOOPBACK_DEV_PART}'"
    dismantle
    exit -1
fi

readonly FS_MOUNT_OUTPUT=$(mount -t btrfs -o subvolid=5,compress-force=zstd:15,noatime,rw "${LOOPBACK_DEV_PART}" "${TARGET_ROOTFS}")
readonly FS_MOUNT_RESULT=$?
if [ $FS_MOUNT_RESULT -eq 0 ]; then
    echo "Image created: '${IMAGE_FILE_PATH}'"
    echo "Image mounted: '${LOOPBACK_DEV_PART}' => '${TARGET_ROOTFS}'"
    export MOUNTED_LOOPBACK_PART="${LOOPBACK_DEV_PART}"
else
    echo "ERROR: Could not mount the target loopback partition '${LOOPBACK_DEV_PART}'"
    dismantle
    exit -1
fi
echo "----------------------------------------------------------"

# Initialize the mounted rootfs
echo "------------------- root filesystem ----------------------"
readonly ROOTFS_CREATE_OUTPUT=$(bash "${CURRENT_SCRIPT_DIR}/utils/prepare_rootfs.sh" "$TARGET_ROOTFS" "$HOME_SUBVOL_NAME" "$DEPLOYMENT_SUBVOL_NAME" "$DEPLOYMENTS_DIR" "$DEPLOYMENTS_DATA_DIR")
readonly ROOTFS_CREATE_RESULT=$?

echo "$ROOTFS_CREATE_OUTPUT"
if [ $ROOTFS_CREATE_RESULT -eq 0 ]; then
    echo "rootfs initialized: '${TARGET_ROOTFS}'"
else
    echo "ERROR: Unable to initialize the root filesystem"
    dismantle
    exit -1
fi
echo "----------------------------------------------------------"

# Get the UUID of the partition
readonly REALPATH_EXTRACTED_ROOTFS_HOST_PATH=$(realpath -s "${EXTRACTED_ROOTFS_HOST_PATH}")
readonly REALPATH_SNAPSHOT=$(realpath -s "${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}/${DEPLOYMENT_SUBVOL_NAME}")

echo "---------------- Filesystem ------------------------------"
if [ ! -d "$REALPATH_EXTRACTED_ROOTFS_HOST_PATH" ]; then
    btrfs subvolume create "${EXTRACTED_ROOTFS_HOST_PATH}"
fi

echo "Searching for the rootfs..."
readonly ROOTFS_TAR_FILE=$(find "${BINARIES_DIR}" -name '*rootfs*.tar*' | head -n 1)
if [ -f "${ROOTFS_TAR_FILE}" ]; then
    echo "Unpacking '${ROOTFS_TAR_FILE}' on the deployment subvolume..."
    tar xpf "${ROOTFS_TAR_FILE}" -C "${EXTRACTED_ROOTFS_HOST_PATH}"
else
    echo "No tar rootfs found."
    dismantle
    exit -1
fi

# Avoid failing due to fstab not finding these
mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/usr"
mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/opt"
mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/root"
mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/etc"
mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/var"
echo "----------------------------------------------------------"

echo "---------------- Boot Process ----------------------------"
if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/stupid1" ]; then
    echo "stuPID1 has been found: setting it as the default init program."
    if [ -L "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init" ]; then
        echo "/sbin/init found: removing default one"
        rm "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init"
    fi

    if ! ln -sf "/usr/bin/stupid1" "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init"; then
        echo "Unable to link /sbin/init -> /usr/bin/stupid1"
        dismantle
        exit -1
    fi

    if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/atomrootfsinit" ]; then
        echo "atomrootfsinit has been found: setting it as a second stage after stuPID1."
        if ! ln -sf "/usr/bin/atomrootfsinit" "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/init"; then
            echo "Unable to link /usr/bin/init -> /usr/bin/atomrootfsinit"
            dismantle
            exit -1
        fi
    fi
elif [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/atomrootfsinit" ]; then
    if [ -L "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init" ]; then
        echo "/sbin/init found: removing default one"
        rm "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init"
    fi
    
    echo "atomrootfsinit has been found: setting it as first stage."
    if ! ln -sf "/usr/bin/atomrootfsinit" "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init"; then
        echo "Unable to link /sbin/init -> /usr/bin/atomrootfsinit"
        dismantle
        exit -1
    fi
else
    echo "Neither stuPID1 nor atomrootfsinit have been found: not touching /sbin/init"
fi

echo "------------------ PAM Module ----------------------------"

if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth" ]; then
    sed -i '/^[-]auth\s\+sufficient\s\+pam_unix.so/a -auth     sufficient pam_login_ng.so' "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth"
    sed -i '/^[-]account\s\+required\s\+pam_nologin.so/a -account  sufficient pam_login_ng.so' "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth"
    sed -i '/^[-]session\s\+optional\s\+pam_loginuid.so/a -session  optional   pam_login_ng.so' "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth"
fi

echo "----------------------------------------------------------"

# TODO: symlink '/home/user/.config/systemd/user/dbus.service' → '/usr/lib/systemd/user/dbus-broker.service'
# TODO: symlink '/home/user/.config/systemd/user/pipewire-session-manager.service' → '/usr/lib/systemd/user/wireplumber.service'.
# TODO: symlink '/home/user/.config/systemd/user/pipewire.service.wants/wireplumber.service' → '/usr/lib/systemd/user/wireplumber.service'.

echo "------------------ Autologin ----------------------------"

if ! btrfs subvol create "${TARGET_ROOTFS}/user_data"; then
    echo "Error setting the autologin user's data subvolume"
    dismantle
    exit -1
fi

echo "----------------------------------------------------------"

echo "------------------- /etc/fstab ---------------------------"

# write /etc/fstab with mountpoints
if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/lib/systemd/systemd" ]; then
    echo "LABEL=rootfs /home btrfs   rw,noatime,subvol=/${HOME_SUBVOL_NAME},skip_balance,compress=zstd    0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
    echo "LABEL=rootfs /mnt btrfs   remount,rw,noatime,x-initrd.mount,subvol=/,skip_balance,compress=zstd 0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
else
    echo "/dev/root /home btrfs   rw,noatime,subvol=/${HOME_SUBVOL_NAME},skip_balance,compress=zstd       0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
    echo "/dev/root /mnt btrfs   remount,rw,noatime,x-initrd.mount,subvol=/,skip_balance,compress=zstd    0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
fi

# [1] following two lines makes systemd believe it's running in degraded mode because even if ro is specified the work directory is being created (and thus that fails)
#echo "overlay /usr  overlay ro,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,lowerdir=/usr,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null                              0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
#echo "overlay /opt  overlay ro,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,lowerdir=/opt,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null                              0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
echo "overlay /root overlay remount,rw,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,x-systemd.rw-only,lowerdir=/root,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/root_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/root_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null 0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
echo "overlay /etc  overlay remount,rw,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,x-systemd.rw-only,lowerdir=/etc,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/etc_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/etc_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null    0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
echo "overlay /var  overlay remount,rw,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,x-systemd.rw-only,lowerdir=/var,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/var_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/var_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null    0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"

echo "----------------------------------------------------------"

# since systemd wants to write /etc/machine-id before mounting things in /etc/fstab and missing /etc/machine-id means dbus-broker breaking
# if it is available then configure atomrootfsinit to pre-mount /etc and /var
if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/atomrootfsinit" ]; then
    # kernel auto-mounts /dev
    #echo "dev                   /mnt/dev  devtmpfs rw 0 0" > "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdtab"

    echo "dev     /mnt/dev  devtmpfs rw 0 0" > "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdtab"
    echo "proc    /mnt/proc proc     rw 0 0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdtab"
    echo "sys     /mnt/sys  sysfs    rw 0 0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdtab"
    echo "rootdev /mnt/mnt  btrfs    rw,noatime,subvol=/,skip_balance,compress=zstd 0 0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdtab"
    echo "overlay /mnt/root overlay  rw,noatime,lowerdir=/mnt/root,upperdir=/mnt/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/root_overlay/upperdir,workdir=/mnt/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/root_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off 0 0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdtab"
    echo "overlay /mnt/etc  overlay  rw,noatime,lowerdir=/mnt/etc,upperdir=/mnt/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/etc_overlay/upperdir,workdir=/mnt/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/etc_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off    0 0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdtab"
    echo "overlay /mnt/var  overlay  rw,noatime,lowerdir=/mnt/var,upperdir=/mnt/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/var_overlay/upperdir,workdir=/mnt/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/var_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off    0 0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdtab"
fi

# see [1]
#echo "#!/bin/sh" > "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/remount_overlay.sh"
#echo "btrfs property set -fts /mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay ro false" >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/remount_overlay.sh"
#echo "btrfs property set -fts /mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay ro false" >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/remount_overlay.sh"
#echo "mount -t overlay -o remount,rw,noatime,lowerdir=/usr,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null overlay /usr" >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/remount_overlay.sh"
#echo "mount -t overlay -o remount,rw,noatime,lowerdir=/opt,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null overlay /opt" >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/remount_overlay.sh"

#echo "${DEPLOYMENT_SUBVOL_NAME}" > "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdname"

# prapare the deployment snapshot
mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/usr/lib/embedded_quickstart"
echo "${DEPLOYMENT_SUBVOL_NAME}" > "${EXTRACTED_ROOTFS_HOST_PATH}/usr/lib/embedded_quickstart/version"

install -D -m 755 "${CURRENT_SCRIPT_DIR}/install.sh" "${EXTRACTED_ROOTFS_HOST_PATH}/usr/lib/embedded_quickstart/install"
install -D -m 755 "${CURRENT_SCRIPT_DIR}/uninstall.sh" "${EXTRACTED_ROOTFS_HOST_PATH}/usr/lib/embedded_quickstart/uninstall"

echo "--------------------- BTRFS ------------------------------"

# Seal the roofs
echo "Sealing the BTRFS subvolume containing the rootfs"
btrfs property set -fts "${EXTRACTED_ROOTFS_HOST_PATH}" ro true

echo "Sealing the main subvolume"
btrfs property set -fts "${TARGET_ROOTFS}" ro true

# Generate the deployment snapshot
if [[ "$REALPATH_EXTRACTED_ROOTFS_HOST_PATH" != "$REALPATH_SNAPSHOT" ]]; then
    btrfs subvolume snapshot -r "${EXTRACTED_ROOTFS_HOST_PATH}" "${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}/${DEPLOYMENT_SUBVOL_NAME}"
fi

btrfs send "${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}/${DEPLOYMENT_SUBVOL_NAME}" > "${BINARIES_DIR}/${DEPLOYMENT_SUBVOL_NAME}.btrfs"
cat "${BINARIES_DIR}/${DEPLOYMENT_SUBVOL_NAME}.btrfs" | xz -9e --memory=95% -T0 > "${BINARIES_DIR}/${DEPLOYMENT_SUBVOL_NAME}.btrfs.xz"

# Change the default subvolid so that the written deployment will get booted
readonly ROOTFS_DEFAULT_SUBVOLID=$("${CURRENT_SCRIPT_DIR}/utils/btrfs_get_subvolid.sh" "${TARGET_ROOTFS}/${DEPLOYMENTS_DIR}/${DEPLOYMENT_SUBVOL_NAME}")
readonly ROOTFS_DEFAULT_SUBVOLID_FETCH_RESULT=$?

if [ $ROOTFS_DEFAULT_SUBVOLID_FETCH_RESULT -eq 0 ]; then
    if [ "${ROOTFS_DEFAULT_SUBVOLID}" = "5" ]; then
        echo "ERROR: Invalid subvolid for the rootfs subvolume"
        dismantle
        exit -1
    elif [ -z "${ROOTFS_DEFAULT_SUBVOLID}" ]; then
        echo "ERROR: Couldn't identify the correct subvolid of the deployment"
        dismantle
        exit -1
    fi

    if btrfs subvolume set-default "${ROOTFS_DEFAULT_SUBVOLID}" "${TARGET_ROOTFS}"; then
        echo "Default subvolume for rootfs set to $ROOTFS_DEFAULT_SUBVOLID"
    else
        echo "ERROR: Could not change the default subvolid of '${TARGET_ROOTFS}' to subvolid=$ROOTFS_DEFAULT_SUBVOLID"
        dismantle
        exit -1
    fi
else
    echo "ERROR: Unable to identify the subvolid for the rootfs subvolume"
    dismantle
    exit -1
fi

echo "----------------------------------------------------------"

# Umount the filesyste and the loopback device
dismantle

sync

echo "Image generated successfully!"
