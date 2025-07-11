#!/bin/bash

set -e

export TARGET_ROOTFS="/mnt"
export EXTRACTED_ROOTFS_HOST_PATH=""

LNG_CTL="login_ng-ctl"

if [ ! -d "/etc/autologin" ]; then
    echo "No autologin data to be applied"
    exit 0
fi

if [ ! -f "${EXTRACTED_ROOTFS_HOST_PATH}/etc/autologin/user_autologin_username" ]; then
    echo "No autologin specified"
    exit 0
fi

AUTOLOGIN_UID=$(cat "${EXTRACTED_ROOTFS_HOST_PATH}/etc/autologin/user_autologin_uid")
AUTOLOGIN_GID=$(cat "${EXTRACTED_ROOTFS_HOST_PATH}/etc/autologin/user_autologin_gid")
AUTOLOGIN_USERNAME=$(cat "${EXTRACTED_ROOTFS_HOST_PATH}/etc/autologin/user_autologin_username")
AUTOLOGIN_MAIN_PASSWORD=$(cat "${EXTRACTED_ROOTFS_HOST_PATH}/etc/autologin/user_autologin_main_password")
AUTOLOGIN_INTERMEDIATE_KEY=$(cat "${EXTRACTED_ROOTFS_HOST_PATH}/etc/autologin/user_autologin_intermediate_key")

AUTOLOGIN_USER_HOME_DIR="/home/$AUTOLOGIN_USERNAME"

useradd -d "$AUTOLOGIN_USER_HOME_DIR" -m -e 2199-12-31 $AUTOLOGIN_USERNAME

echo "$AUTOLOGIN_USERNAME:$AUTOLOGIN_MAIN_PASSWORD" | chpasswd

# add more permissions to the greeter user
usermod -aG render greeter
usermod -aG seat greeter
usermod -aG input greeter

# add groups to be able to render the GUI application
usermod -aG render $AUTOLOGIN_USERNAME
usermod -aG video $AUTOLOGIN_USERNAME
usermod -aG audio $AUTOLOGIN_USERNAME
usermod -aG seat $AUTOLOGIN_USERNAME
usermod -aG input $AUTOLOGIN_USERNAME
usermod -aG tty $AUTOLOGIN_USERNAME

if "${LNG_CTL}" -d "${AUTOLOGIN_USER_HOME_DIR}" -p "${AUTOLOGIN_MAIN_PASSWORD}" setup -i "${AUTOLOGIN_INTERMEDIATE_KEY}"; then
    if "${LNG_CTL}" -d "${AUTOLOGIN_USER_HOME_DIR}" add --name "autologin" --intermediate "${AUTOLOGIN_INTERMEDIATE_KEY}" password --secondary-pw ""; then
        echo "------------------ Autologin User ------------------------"
        echo "Username: ${AUTOLOGIN_USERNAME}"
        echo "Main Password: ${AUTOLOGIN_MAIN_PASSWORD}"
        echo "Intermediate Key: ${AUTOLOGIN_INTERMEDIATE_KEY}"
        echo "----------------------------------------------------------"
        echo ""
        echo ""
    else
        echo "Error setting up the user autologin"
        exit -1
    fi

    readonly hashed_password=$(openssl passwd -6 -salt xyz "${AUTOLOGIN_MAIN_PASSWORD}")

    if ! echo "${AUTOLOGIN_USERNAME}:x:${AUTOLOGIN_UID}:${AUTOLOGIN_GID}::/home/${AUTOLOGIN_USERNAME}:/bin/bash" | tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/passwd"; then
        echo "Error writing the /etc/passwd file"
        exit -1
    fi

    if ! echo "${AUTOLOGIN_USERNAME}:${hashed_password}:18000:0:99999:7:-1:-1:" | tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/shadow"; then
        echo "Error writing the /etc/shadow file"
        exit -1
    fi

    if ! echo "${AUTOLOGIN_USERNAME}:x:${AUTOLOGIN_GID}:" | tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/group"; then
        echo "Error writing the /etc/group file"
        exit -1
    fi

    if [ ! -d "${TARGET_ROOTFS}/user_data" ]; then
        if ! btrfs subvol create "${TARGET_ROOTFS}/user_data"; then
            echo "Error setting the autologin user's data subvolume"
            exit -1
        fi
    fi

    mkdir -p "${TARGET_ROOTFS}/user_data/upperdir"
    mkdir -p "${TARGET_ROOTFS}/user_data/workdir"
    chown ${AUTOLOGIN_UID}:${AUTOLOGIN_GID} "${TARGET_ROOTFS}/user_data/upperdir"
    chown ${AUTOLOGIN_UID}:${AUTOLOGIN_GID} "${TARGET_ROOTFS}/user_data/workdir"

    if ! "${LNG_CTL}" -d "${AUTOLOGIN_USER_HOME_DIR}" set-home-mount --device "overlay" --fstype "overlay" --flags "lowerdir=/home/user,upperdir=${TARGET_ROOTFS}/user_data/upperdir,workdir=${TARGET_ROOTFS}/user_data/workdir,index=off,metacopy=off,xino=off,redirect_dir=off"; then
        echo "Error setting the user home mount"
        exit -1
    fi

    # Create the service directory
    if ! mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/"; then
        echo "Error in creating ${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/"
        exit -1
    fi

    # Authorize the mount
    AUTOLOGIN_USER_MOUNTS_HASH=$("${LNG_CTL}" -d "${AUTOLOGIN_USER_HOME_DIR}" inspect | awk '/hash:/ {print $2}')
    AUTOLOGIN_USER_MOUNTS_HASH_GET_RESULT=$?
    if [ $AUTOLOGIN_USER_MOUNTS_HASH_GET_RESULT -eq 0 ]; then
        echo ""
        echo ""
        echo "---------------- Authorized Mounts -----------------------"
        echo "{" | tee "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
        echo "    \"authorizations\": {" | tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
        echo "        \"${AUTOLOGIN_USERNAME}\": [" | tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
        echo "            \"${AUTOLOGIN_USER_MOUNTS_HASH}\"" | tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
        echo "        ]" | tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
        echo "    }" | tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
        echo "}" | tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/etc/login_ng/authorized_mounts.json"
        echo "----------------------------------------------------------"
        echo ""
        echo ""
        echo "----------------- Autologin Review -----------------------"
        "${LNG_CTL}" -d "${AUTOLOGIN_USER_HOME_DIR}" inspect
        echo "----------------------------------------------------------"
    else
        echo "Error fetching autologin user's mounts"
        exit -1
    fi
else
    echo "Error setting up the user login data"
    exit -1
fi

chown -R ${AUTOLOGIN_UID}:${AUTOLOGIN_GID} "${AUTOLOGIN_USER_HOME_DIR}"

# set the default autologin command
if [ -f "/etc/autologin/user_autologin_cmd" ]; then
    AUTOLOGIN_CMD=$(cat "/etc/autologin/user_autologin_cmd")
    sed -i -e "s|/usr/bin/login_ng-cli|/usr/bin/login_ng-cli -c '${AUTOLOGIN_CMD}' -u ${AUTOLOGIN_USERNAME}|" "${EXTRACTED_ROOTFS_HOST_PATH}/etc/greetd/config.toml"
fi

rm -rf "/etc/autologin"

sync
