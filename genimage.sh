#!/bin/bash

set -eE -o functrace

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
    local lineno=$1
    local msg=$2
    echo "Error occurred at line ${lineno}: ${msg}"
    dismantle
}

# Set the trap to call the error_handler function on ERR
trap 'error_handler ${LINENO} "$BASH_COMMAND"' ERR

readonly CURRENT_SCRIPT_DIR="${BASH_SOURCE%/*}"

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

if [ -d "${BINARIES_DIR}" ]; then
    if [ ! -f "${IMAGE_FILE_PATH}" ]; then
        echo "Image Disk file not found: creating a new one"
        # Less than 2GB will fail to host the rootfs
        if ! fallocate -l 2G "${IMAGE_FILE_PATH}"; then
            echo "ERROR: Could not allocate space for target file '${IMAGE_FILE_PATH}'"
            exit -1
        fi
    fi
else
    echo "ERROR: Directory ${BINARIES_DIR} does not exists"
    exit -5
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

echo "Prepared loopback device: '${LOOPBACK_OUTPUT}'"

SECURE_BOOT_KEY=""
if [ -f "${BINARIES_DIR}/imx-boot" ]; then
    export IMAGE_PART_NUMBER="1"

    parted -s "${LOOPBACK_OUTPUT}" mklabel msdos

    echo "Creating the rootfs partition..."

    parted -s "${LOOPBACK_OUTPUT}" --script mkpart primary btrfs 8MiB 100%

    echo "Writing the bootloader..."
    if ! dd if="${BINARIES_DIR}/imx-boot" of="${LOOPBACK_OUTPUT}" bs=1K seek=33 conv=fsync ; then
        echo "ERROR: Could not write imx-boot to image"
        dismantle
        exit -1
    fi
elif [ -f "${BINARIES_DIR}/grub-efi-bootx64.efi" ]; then
    export IMAGE_PART_NUMBER="2"

    parted -s "${LOOPBACK_OUTPUT}" mklabel gpt

    echo "Creating EFI System Partition..."

    parted --script "${LOOPBACK_OUTPUT}" \
		mkpart primary fat32 1MiB 100MiB \
		type 1 "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" \
		set 1 esp on

    echo "Creating the rootfs partition..."

    parted --script "${LOOPBACK_OUTPUT}" \
        mkpart primary btrfs 100MiB 100% \
        type $IMAGE_PART_NUMBER "4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709"

    mkfs.vfat -F32 "${LOOPBACK_OUTPUT}p1" -n BOOTEFI

    readonly REFIND_NAME="refind-bin-0.14.2"
    rm -rf "${CURRENT_SCRIPT_DIR}/refind_temp"
    unzip "${CURRENT_SCRIPT_DIR}/${REFIND_NAME}.zip" -d "${CURRENT_SCRIPT_DIR}/refind_temp"

    echo "Writing the EFI bootloader ${REFIND_NAME}..."

    mount "${LOOPBACK_OUTPUT}p1" "${TARGET_ROOTFS}"
    mkdir -p "${TARGET_ROOTFS}/EFI/BOOT"

    cp "${CURRENT_SCRIPT_DIR}/refind_temp/${REFIND_NAME}/refind/refind_x64.efi" "${TARGET_ROOTFS}/EFI/BOOT/BOOTX64.EFI"
    cp -a "${CURRENT_SCRIPT_DIR}/refind_temp/${REFIND_NAME}/refind" "${TARGET_ROOTFS}/EFI/"
    rm "${TARGET_ROOTFS}/EFI/refind/refind.conf-sample"

    cp "${CURRENT_SCRIPT_DIR}/refind.conf" "${TARGET_ROOTFS}/EFI/refind/"

    readonly ROOTFS_PARTUUID=$(blkid -s PARTUUID -o value "${LOOPBACK_OUTPUT}p${IMAGE_PART_NUMBER}")
    readonly ROOTFS_PARTUUID_RESULT=$?
    if [ $ROOTFS_PARTUUID_RESULT -eq 0 ]; then
        echo "Configuring rEFInd to start: rootfs on PARTUUID='${ROOTFS_PARTUUID}'"

        echo 'menuentry "Embedded Linux" {' >> "${TARGET_ROOTFS}/EFI/refind/refind.conf"
        echo '    volume "rootfs"' >> "${TARGET_ROOTFS}/EFI/refind/refind.conf"
        echo '    loader /boot/bzImage' >> "${TARGET_ROOTFS}/EFI/refind/refind.conf"
        echo "    options \"root=PARTUUID=$ROOTFS_PARTUUID ro rootfstype=btrfs rootdelay=2 video=efifb:1920x1080\" add_efi_memmap lsm=landlock,lockdown,yama,integrity,selinux,bpf" >> "${TARGET_ROOTFS}/EFI/refind/refind.conf"
        echo '    icon EFI/refind/icons/os_linux.png' >> "${TARGET_ROOTFS}/EFI/refind/refind.conf"
        echo '}' >> "${TARGET_ROOTFS}/EFI/refind/refind.conf"
        echo '' >> "${TARGET_ROOTFS}/EFI/refind/refind.conf"
        echo 'default_selection "Embedded Linux"' >> "${TARGET_ROOTFS}/EFI/refind/refind.conf"
    else
        echo "ERROR: Could not fetch the PARTUUID of the rootfs partition"
        dismantle
        exit -1
    fi

    rm -rf "${CURRENT_SCRIPT_DIR}/shim"
    git clone https://github.com/rhboot/shim.git "${CURRENT_SCRIPT_DIR}/shim"
    if ! bash -i -c "cd ${CURRENT_SCRIPT_DIR}/shim && git checkout 16.1 && git submodule update --init"; then
        echo "ERROR: Could not checkout shim"
        dismantle
        exit -1
    fi

    if [ ! -d "${CURRENT_SCRIPT_DIR}/secure_boot" ]; then
        mkdir -p "${CURRENT_SCRIPT_DIR}/secure_boot"
        if ! bash -i -c "cd ${CURRENT_SCRIPT_DIR}/secure_boot && ${CURRENT_SCRIPT_DIR}/create_efi_key.sh"; then
            echo "ERROR: Could not prepare secure boot keys"
            dismantle
            exit -1
        fi
    fi

    SECURE_BOOT_CRT="${CURRENT_SCRIPT_DIR}/secure_boot/db.crt"
    SECURE_BOOT_KEY="${CURRENT_SCRIPT_DIR}/secure_boot/db.key"

    # For this to work install libelf-dev
    rm -rf "${CURRENT_SCRIPT_DIR}/shim_install"
    mkdir "${CURRENT_SCRIPT_DIR}/shim_install"
    if ! make EFIDIR="${TARGET_ROOTFS}" -C "${CURRENT_SCRIPT_DIR}/shim" DESTDIR="${CURRENT_SCRIPT_DIR}/shim_install" DEFAULT_LOADER='\\EFI\\refind\\refind_x64.efi' OSLABEL=refind ENABLE_SHIM_CERT=y install; then
        echo "ERROR: Could not build shim"
        dismantle
        exit -1
    fi

    # Install shim
    mkdir -p "${TARGET_ROOTFS}/EFI/BOOT"
    if ! sbsign --key "$SECURE_BOOT_KEY" --cert "$SECURE_BOOT_CRT" --output "${TARGET_ROOTFS}/EFI/BOOT/BOOTX64.EFI" "${CURRENT_SCRIPT_DIR}/shim_install/boot/efi/EFI/BOOT/BOOTX64.EFI"; then
        echo "ERROR: Could not sign shim"
        dismantle
        exit -1
    fi

    # Sign refind if it was installed
    if [ -f "${TARGET_ROOTFS}/EFI/refind/refind_x64.efi" ]; then
        # sign the bootloader
        if ! sbsign --key "$SECURE_BOOT_KEY" --cert "$SECURE_BOOT_CRT" --output "${TARGET_ROOTFS}/EFI/refind/refind_x64.efi" "${TARGET_ROOTFS}/EFI/refind/refind_x64.efi"; then
            echo "ERROR: Could not sign refind for secure boot"
            dismantle
            exit -1
        fi

        # Install mmx64.efi
        if ! sbsign --key "$SECURE_BOOT_KEY" --cert "$SECURE_BOOT_CRT" --output "${TARGET_ROOTFS}/EFI/BOOT/mmx64.efi" "${CURRENT_SCRIPT_DIR}/shim_install/boot/efi/EFI/BOOT/mmx64.efi"; then
            echo "ERROR: Could not sign mmx64.efi"
            dismantle
            exit -1
        else
            cp "${TARGET_ROOTFS}/EFI/BOOT/mmx64.efi" "${TARGET_ROOTFS}/EFI/refind/mmx64.efi"
        fi

    ## Install fbx64.efi
    #if ! sbsign --key "$SECURE_BOOT_KEY" --cert "$SECURE_BOOT_CRT" --output "${TARGET_ROOTFS}/EFI/BOOT/fbx64.efi" "${CURRENT_SCRIPT_DIR}/shim_install/boot/efi/EFI/BOOT/fbx64.efi"; then
    #    echo "ERROR: Could not sign fbx64.efi"
    #    dismantle
    #    exit -1
    #fi

        # sign btrfs_x64.efi
        if ! sbsign --key "$SECURE_BOOT_KEY" --cert "$SECURE_BOOT_CRT" --output "${TARGET_ROOTFS}/EFI/refind/drivers_x64/btrfs_x64.efi" "${TARGET_ROOTFS}/EFI/refind/drivers_x64/btrfs_x64.efi"; then
            echo "ERROR: Could not sign btrfs_x64.efi for secure boot"
            dismantle
            exit -1
        fi

        # sign ext4_x64.efi
        if ! sbsign --key "$SECURE_BOOT_KEY" --cert "$SECURE_BOOT_CRT" --output "${TARGET_ROOTFS}/EFI/refind/drivers_x64/ext4_x64.efi" "${TARGET_ROOTFS}/EFI/refind/drivers_x64/ext4_x64.efi"; then
            echo "ERROR: Could not sign ext4_x64.efi.efi for secure boot"
            dismantle
            exit -1
        fi

        # sign ext2_x64.efi
        if ! sbsign --key "$SECURE_BOOT_KEY" --cert "$SECURE_BOOT_CRT" --output "${TARGET_ROOTFS}/EFI/refind/drivers_x64/ext2_x64.efi" "${TARGET_ROOTFS}/EFI/refind/drivers_x64/ext2_x64.efi"; then
            echo "ERROR: Could not sign ext2_x64.efi for secure boot"
            dismantle
            exit -1
        fi

        # sign iso9660_x64.efi
        if ! sbsign --key "$SECURE_BOOT_KEY" --cert "$SECURE_BOOT_CRT" --output "${TARGET_ROOTFS}/EFI/refind/drivers_x64/iso9660_x64.efi" "${TARGET_ROOTFS}/EFI/refind/drivers_x64/iso9660_x64.efi"; then
            echo "ERROR: Could not sign iso9660_x64.efi for secure boot"
            dismantle
            exit -1
        fi

        # sign reiserfs_x64.efi
        if ! sbsign --key "$SECURE_BOOT_KEY" --cert "$SECURE_BOOT_CRT" --output "${TARGET_ROOTFS}/EFI/refind/drivers_x64/reiserfs_x64.efi" "${TARGET_ROOTFS}/EFI/refind/drivers_x64/reiserfs_x64.efi"; then
            echo "ERROR: Could not sign reiserfs_x64.efi for secure boot"
            dismantle
            exit -1
        fi

        # sign hfs_x64.efi
        if ! sbsign --key "$SECURE_BOOT_KEY" --cert "$SECURE_BOOT_CRT" --output "${TARGET_ROOTFS}/EFI/refind/drivers_x64/hfs_x64.efi" "${TARGET_ROOTFS}/EFI/refind/drivers_x64/hfs_x64.efi"; then
            echo "ERROR: Could not sign hfs_x64.efi for secure boot"
            dismantle
            exit -1
        fi

    fi

    mkdir -p "${TARGET_ROOTFS}/keys/"
    cp "${CURRENT_SCRIPT_DIR}/secure_boot/old_dbx.esl" "${TARGET_ROOTFS}/keys/dbx.esl"
    cp "${CURRENT_SCRIPT_DIR}/secure_boot/db.esl" "${TARGET_ROOTFS}/keys/"
    cp "${CURRENT_SCRIPT_DIR}/secure_boot/KEK.esl" "${TARGET_ROOTFS}/keys/"
    cp "${CURRENT_SCRIPT_DIR}/secure_boot/PK.esl" "${TARGET_ROOTFS}/keys/"

    umount "${TARGET_ROOTFS}"
else
    echo "Unsupported hardware."
    dismantle
    exit -1
fi

sync

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
readonly ROOTFS_TAR_FILE=$(find "${BINARIES_DIR}" -name '*rootfs*.tar*' | grep -v ".spdx" | head -n 1)
if [ -f "${ROOTFS_TAR_FILE}" ]; then
    echo "Unpacking '${ROOTFS_TAR_FILE}' on the deployment subvolume..."
    tar xpf "${ROOTFS_TAR_FILE}" -C "${EXTRACTED_ROOTFS_HOST_PATH}"
else
    echo "ERROR: No tar rootfs found."
    dismantle
    exit -1
fi

if [ -f "$SECURE_BOOT_KEY" ] && [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/boot/bzImage" ]; then
    if ! sbsign --key "$SECURE_BOOT_KEY" --cert "$SECURE_BOOT_CRT" --output "${EXTRACTED_ROOTFS_HOST_PATH}/boot/bzImage" "${EXTRACTED_ROOTFS_HOST_PATH}/boot/bzImage"; then
        echo "ERROR: could not sign kernel for secure boot."
        dismantle
        exit -1
    else
        echo "bzImage signed successfully"
    fi
else
    echo "Secure boot key not found: kernel won't be signed"
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
        mv "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init" "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init_stage2"
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
        mv "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init" "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init_stage2"
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

if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/sbin/init_stage2" ]; then
    echo '/sbin/init_stage2' > "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdexec"
elif [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/lib/systemd/systemd" ]; then
    echo '/usr/lib/systemd/systemd' > "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdexec"
fi

echo "----------------------------------------------------------"

echo "------------------ Device Trees --------------------------"

mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/boot"

for dtb_file_path in "${BINARIES_DIR}"/*.dtb; do
    # Check if the file exists to avoid errors if no .dtb files are found
    if [ -e "$dtb_file_path" ]; then
        dtb_file_name=$(basename $dtb_file_path)
        dtb_file_path_dest="${EXTRACTED_ROOTFS_HOST_PATH}/boot/${dtb_file_name}"
        if [ ! -f "$dtb_file_path_dest" ]; then
            echo "DTB[Y]: ${dtb_file_name}"
            cp "$dtb_file_path" "${dtb_file_path_dest}"
        else
            echo "DTB[N]: ${dtb_file_name}"
        fi
    else
        echo "No .dtb files found in $SOURCE_DIR"
        break
    fi
done

echo "----------------------------------------------------------"

echo "------------------ PAM Module ----------------------------"

if [ ! -f "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth" ]; then
    # I have absolutely no idea why this should be even needed... But it is. ffs.
    cp "${CURRENT_SCRIPT_DIR}/pam_example/system-auth" "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth"

    echo "Copied system-auth PAM configuration file"
fi

for file in $EXTRACTED_ROOTFS_HOST_PATH/etc/pam.d/*; do
    pam_selinux_location=$(find "${EXTRACTED_ROOTFS_HOST_PATH}/usr" -name "pam_selinux.so")
    if [ -z "$pam_selinux_location" ]; then
        if [ -f "$file" ]; then
            sed -i '/pam_selinux.so/s/^/#/' "$file"
        fi
    fi

    pam_console_location=$(find "${EXTRACTED_ROOTFS_HOST_PATH}/usr" -name "pam_console.so")
    if [ -z "$pam_console_location" ]; then
        if [ -f "$file" ]; then
            sed -i '/pam_console.so/s/^/#/' "$file"
        fi
    fi
done

touch "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam_debug"

if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth" ]; then
    sed -i '/^-\?auth\s\+\(required\|sufficient\|optional\)\s\+pam_unix.so/a -auth     sufficient pam_polyauth.so' "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth"
    sed -i '/^-\?account\s\+\(required\|sufficient\|optional\)\s\+pam_unix.so/a -account  sufficient pam_polyauth.so' "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth"
    sed -i '/^-\?session\s\+\(required\|sufficient\|optional\)\s\+pam_unix.so/a -session  optional   pam_polyauth.so' "${EXTRACTED_ROOTFS_HOST_PATH}/etc/pam.d/system-auth"
fi

echo "----------------------------------------------------------"

echo "-------------------- login_ng ----------------------------"

if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/etc/greetd/config.toml" ] && [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/login_ng-cli" ]; then
    sed -i 's|agreety --cmd /bin/sh|/usr/bin/login_ng-cli --autologin true|' "${EXTRACTED_ROOTFS_HOST_PATH}/etc/greetd/config.toml"
fi

echo "----------------------------------------------------------"

# TODO: symlink '/home/user/.config/systemd/user/dbus.service' → '/usr/lib/systemd/user/dbus-broker.service'
# TODO: symlink '/home/user/.config/systemd/user/pipewire-session-manager.service' → '/usr/lib/systemd/user/wireplumber.service'.
# TODO: symlink '/home/user/.config/systemd/user/pipewire.service.wants/wireplumber.service' → '/usr/lib/systemd/user/wireplumber.service'.

echo "-------------------- Autologin ---------------------------"

if ! btrfs subvol create "${TARGET_ROOTFS}/user_data"; then
    echo "Error setting the autologin user's data subvolume"
    dismantle
    exit -1
fi

echo "----------------------------------------------------------"

echo "---------------------- Session ---------------------------"

if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/sessionrunner" ]; then
    if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/wayland-sessions/weston.desktop" ]; then
        ln -s weston.desktop "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/wayland-sessions/game-mode.desktop"
    fi

    if [ ! -f "${EXTRACTED_ROOTFS_HOST_PATH}/etc/weston.ini" ]; then
        echo '# weston configuration generated from genimage.sh' >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/weston.ini"
        echo '[core]' >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/weston.ini"
        echo 'shell=kiosk' >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/weston.ini"
        echo 'backend=drm' >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/weston.ini"
        echo 'idle-time=0' >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/weston.ini"
        echo '' >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/weston.ini"
        echo '[autolaunch]' >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/weston.ini"
        echo 'path=/usr/bin/start-sessionrunner' >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/weston.ini"
        echo 'watch=true' >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/weston.ini"
    fi

fi

echo "----------------------------------------------------------"

echo "------------------- /etc/rdtab ---------------------------"

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
    RDTAB_MOUNTED=",remount"
else
    RDTAB_MOUNTED=""
fi

echo "----------------------------------------------------------"

echo "------------------- /etc/fstab ---------------------------"

# write /etc/fstab with mountpoints
if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/lib/systemd/systemd" ]; then
    echo "LABEL=rootfs /home btrfs   rw,noatime,subvol=/${HOME_SUBVOL_NAME},skip_balance,compress=zstd    0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
    echo "LABEL=rootfs /mnt btrfs   rw${RDTAB_MOUNTED},noatime,x-initrd.mount,subvol=/,skip_balance,compress=zstd 0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
else
    echo "/dev/root /home btrfs   rw,noatime,subvol=/${HOME_SUBVOL_NAME},skip_balance,compress=zstd       0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
    echo "/dev/root /mnt btrfs   rw${RDTAB_MOUNTED},noatime,x-initrd.mount,subvol=/,skip_balance,compress=zstd    0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
fi

# [1] following two lines makes systemd believe it's running in degraded mode because even if ro is specified the work directory is being created (and thus that fails)
#echo "overlay /usr  overlay ro,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,lowerdir=/usr,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null                              0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
#echo "overlay /opt  overlay ro,noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,lowerdir=/opt,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null                              0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
echo "overlay /root overlay rw${RDTAB_MOUNTED},noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,x-systemd.rw-only,lowerdir=/root,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/root_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/root_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null 0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
echo "overlay /etc  overlay rw${RDTAB_MOUNTED},noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,x-systemd.rw-only,lowerdir=/etc,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/etc_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/etc_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null    0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"
echo "overlay /var  overlay rw${RDTAB_MOUNTED},noatime,x-initrd.mount,defaults,x-systemd.requires-mounts-for=/mnt,x-systemd.rw-only,lowerdir=/var,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/var_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/var_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null    0  0" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/fstab"

echo "----------------------------------------------------------"

echo "---------------------- SElinux ---------------------------"

if [ -d "${EXTRACTED_ROOTFS_HOST_PATH}/etc/selinux" ]; then
    echo "# SElinux configuration" > "${EXTRACTED_ROOTFS_HOST_PATH}/etc/selinux/config"
    echo "# SELINUX= can take one of these three values:" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/selinux/config"
    echo "#       enforcing - SELinux security policy is enforced." >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/selinux/config"
    echo "#       permissive - SELinux prints warnings instead of enforcing." >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/selinux/config"
    echo "#       disabled - No SELinux policy is loaded." >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/selinux/config"
    echo "" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/selinux/config"

    if [ -d "${EXTRACTED_ROOTFS_HOST_PATH}/etc/selinux/targeted" ]; then
        echo "SELINUX=enforcing" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/selinux/config"
        echo "Configured SELinux to enforcing mode."
    else
        echo "SELINUX=disabled" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/selinux/config"
        echo "Configured SELinux to disabled mode."
    fi
else
    echo "SELinux not found: skipping configuration."
fi

echo "----------------------------------------------------------"

echo "----------------- /etc/default/qt ------------------------"

if [ -f "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/weston" ]; then
    echo "QT_IM_MODULE=qtvirtualkeyboard" > "${EXTRACTED_ROOTFS_HOST_PATH}/etc/default/qt"
    echo "QTWEBENGINE_DISABLE_SANDBOX=1" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/default/qt"

    echo "#!/bin/sh" > "${EXTRACTED_ROOTFS_HOST_PATH}/etc/start_script.sh"
    echo "" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/start_script.sh"
    echo "if [ -x \"/mnt/app/default\" ]; then" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/start_script.sh"
    echo "    readonly APPLICATION='/mnt/app/hmi'" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/start_script.sh"
    echo "else" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/start_script.sh"
    echo "    readonly APPLICATION='/usr/bin/startupscreen'" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/start_script.sh"
    echo "fi" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/start_script.sh"
    echo "" >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/start_script.sh"
    echo '/usr/bin/appcontroller ${APPLICATION}' >> "${EXTRACTED_ROOTFS_HOST_PATH}/etc/start_script.sh"

    chmod +x "${EXTRACTED_ROOTFS_HOST_PATH}/etc/start_script.sh"
fi

echo "----------------------------------------------------------"

# see [1]
#echo "#!/bin/sh" > "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/remount_overlay.sh"
#echo "btrfs property set -fts /mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay ro false" >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/remount_overlay.sh"
#echo "btrfs property set -fts /mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay ro false" >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/remount_overlay.sh"
#echo "mount -t overlay -o remount,rw,noatime,lowerdir=/usr,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/usr_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null overlay /usr" >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/remount_overlay.sh"
#echo "mount -t overlay -o remount,rw,noatime,lowerdir=/opt,upperdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay/upperdir,workdir=/mnt/${DEPLOYMENTS_DATA_DIR}/${DEPLOYMENT_SUBVOL_NAME}/opt_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,uuid=null overlay /opt" >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/bin/remount_overlay.sh"

#echo "${DEPLOYMENT_SUBVOL_NAME}" > "${EXTRACTED_ROOTFS_HOST_PATH}/etc/rdname"

# prapare the deployment snapshot
mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embuer"

echo "{" > "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embuer/manifest.json"
echo "  \"version\": \"${DEPLOYMENT_SUBVOL_NAME}\"," >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embuer/manifest.json"
echo "  \"readonly\": true," >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embuer/manifest.json"
echo "  \"install_script\": \"/usr/share/embedded_quickstart/install\"," >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embuer/manifest.json"
echo "  \"uninstall_script\": \"$/usr/share/embedded_quickstart/uninstall\"," >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embuer/manifest.json"

# mind absence of comma at the end of the last line
echo "  \"date\": \"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\"" >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embuer/manifest.json"
echo "}" >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embuer/manifest.json"

echo "{" > "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embuer/config.json"
echo "  \"update_url\": \"http://65.21.79.97/update_package.tar\"," >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embuer/config.json"
echo "  \"auto_install_updates\": false," >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embuer/config.json"
echo "" >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embuer/config.json"
echo "  \"rootfs_dir\": \"/mnt\"," >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embuer/config.json"
echo "" >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embuer/config.json"
echo "  \"public_key_pem\": \"/usr/share/embedded_quickstart/public_key_pkcs1.pem\"" >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embuer/config.json"
echo "}" >> "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embuer/config.json"

if [ ! -f "private_key.pem" ]; then
    openssl genrsa -out private_key.pem 2048
    openssl rsa -in private_key.pem -pubout -outform PEM -RSAPublicKey_out -out public_key_pkcs1.pem
fi

mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embedded_quickstart"
cp public_key_pkcs1.pem "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embedded_quickstart/"
install -D -m 755 "${CURRENT_SCRIPT_DIR}/install.sh" "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embedded_quickstart/install"
install -D -m 755 "${CURRENT_SCRIPT_DIR}/uninstall.sh" "${EXTRACTED_ROOTFS_HOST_PATH}/usr/share/embedded_quickstart/uninstall"

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

# Umount the filesystem and the loopback device
dismantle

sync

echo ""
echo ""
echo "Image generated successfully!"

echo "Generating the update package..."

echo 'Version 1.2.0' > "${BINARIES_DIR}/CHANGELOG"
echo '' >> "${BINARIES_DIR}/CHANGELOG"
echo '- Initial release.' >> "${BINARIES_DIR}/CHANGELOG"  
echo '' >> "${BINARIES_DIR}/CHANGELOG"

# Copy deployment data into final destination
cp "${BINARIES_DIR}/${DEPLOYMENT_SUBVOL_NAME}.btrfs.xz" "${BINARIES_DIR}/update.btrfs.xz"

# Generate the signature
openssl dgst -sha512 -sign private_key.pem -out "${BINARIES_DIR}/update.signature" "${BINARIES_DIR}/update.btrfs.xz"

# Check the signature
openssl dgst -sha512 -verify public_key_pkcs1.pem -signature "${BINARIES_DIR}/update.signature" "${BINARIES_DIR}/update.btrfs.xz"

# Create the update tar package compatible with embuer
tar cf "${BINARIES_DIR}/update_package.tar" -C "${BINARIES_DIR}" "CHANGELOG" "update.signature" "update.btrfs.xz"

# Remove copy of deployment data
rm "${BINARIES_DIR}/update.btrfs.xz"
