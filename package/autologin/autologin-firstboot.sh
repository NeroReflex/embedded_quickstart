#!/bin/bash

set -e

# Function to handle errors
error_handler() {
    local lineno=$1
    local msg=$2
    echo "Error occurred at line ${lineno}: ${msg}"
}

# Set the trap to call the error_handler function on ERR
trap 'error_handler ${LINENO} "$BASH_COMMAND"' ERR

if [ "$EUID" -ne 0 ]
    then echo "This script MUST be run as root"
    exit
fi

export TARGET_ROOTFS="/mnt"
export EXTRACTED_ROOTFS_HOST_PATH=""

LNG_CTL="polyauthctl"

if [ ! -d "/etc/autologin" ]; then
    echo "No autologin data to be applied"
    exit -1
fi

if [ ! -f "${EXTRACTED_ROOTFS_HOST_PATH}/etc/autologin/user_autologin_username" ]; then
    echo "No autologin specified"
    exit 0
fi

# If user already exists avoid creating it again
if [ -z "$1" ]; then
    readonly AUTOLOGIN_USERNAME=$(cat "${EXTRACTED_ROOTFS_HOST_PATH}/etc/autologin/user_autologin_username")
    readonly add_user=1
else
    readonly AUTOLOGIN_USERNAME="$1"
    readonly add_user=0
fi
readonly AUTOLOGIN_UID=$(cat "${EXTRACTED_ROOTFS_HOST_PATH}/etc/autologin/user_autologin_uid")
readonly AUTOLOGIN_GID=$(cat "${EXTRACTED_ROOTFS_HOST_PATH}/etc/autologin/user_autologin_gid")
readonly AUTOLOGIN_MAIN_PASSWORD=$(cat "${EXTRACTED_ROOTFS_HOST_PATH}/etc/autologin/user_autologin_main_password")
readonly AUTOLOGIN_INTERMEDIATE_KEY=$(cat "${EXTRACTED_ROOTFS_HOST_PATH}/etc/autologin/user_autologin_intermediate_key")

readonly AUTOLOGIN_CMD="start-sessionrunner"

readonly AUTOLOGIN_USER_HOME_DIR="/home/$AUTOLOGIN_USERNAME"

if [ "$add_user" -eq 1 ]; then
    useradd -d "$AUTOLOGIN_USER_HOME_DIR" -m -e 2199-12-31 $AUTOLOGIN_USERNAME
fi

echo "$AUTOLOGIN_USERNAME:$AUTOLOGIN_MAIN_PASSWORD" | chpasswd

mkdir -p "$AUTOLOGIN_USER_HOME_DIR/.config"
chown $AUTOLOGIN_USERNAME:$AUTOLOGIN_USERNAME "$AUTOLOGIN_USER_HOME_DIR/.config"

# Write weston-vnc.ini file
readonly WESTON_VNC_INI="$AUTOLOGIN_USER_HOME_DIR/.config/weston-vnc.ini"
echo '# weston configuration generated from autologin-firstboot.sh' > "${WESTON_VNC_INI}"
echo '[core]' >> "${WESTON_VNC_INI}"
echo 'shell=kiosk' >> "${WESTON_VNC_INI}"
echo 'backend=vnc' >> "${WESTON_VNC_INI}"
echo 'idle-time=0' >> "${WESTON_VNC_INI}"
echo '' >> "${WESTON_VNC_INI}"
echo '[vnc]' >> "${WESTON_VNC_INI}"
echo 'refresh-rate=15' >> "${WESTON_VNC_INI}"
echo "tls-key=${AUTOLOGIN_USER_HOME_DIR}/.config/tls.key" >> "${WESTON_VNC_INI}"
echo "tls-cert=${AUTOLOGIN_USER_HOME_DIR}/.config/tls.crt" >> "${WESTON_VNC_INI}"

# Write weston.ini file
readonly WESTON_INI="$AUTOLOGIN_USER_HOME_DIR/.config/weston.ini"
echo '# weston configuration generated from autologin-firstboot.sh' > "${WESTON_INI}"
echo '[core]' >> "${WESTON_INI}"
echo 'shell=kiosk' >> "${WESTON_INI}"
#echo 'xwayland=true' >> "${WESTON_INI}"
echo 'modules=screen-share.so' >> "${WESTON_INI}"
echo 'backend=drm' >> "${WESTON_INI}"
echo 'idle-time=0' >> "${WESTON_INI}"
echo '' >> "${WESTON_INI}"
echo '[screen-share]' >> "${WESTON_INI}"
echo "command=/usr/bin/weston --config=$WESTON_VNC_INI" >> "${WESTON_INI}"
echo 'start-on-startup=true' >> "${WESTON_INI}"
echo '' >> "${WESTON_INI}"
echo '[autolaunch]' >> "${WESTON_INI}"
echo 'path=/etc/start_script.sh' >> "${WESTON_INI}"
echo 'watch=true' >> "${WESTON_INI}"

mkdir -p "${TARGET_ROOTFS}/user_data/upperdir"
mkdir -p "${TARGET_ROOTFS}/user_data/workdir"
chown ${AUTOLOGIN_UID}:${AUTOLOGIN_GID} "${TARGET_ROOTFS}/user_data/upperdir"
chown ${AUTOLOGIN_UID}:${AUTOLOGIN_GID} "${TARGET_ROOTFS}/user_data/workdir"
mount -t overlay -o lowerdir=$AUTOLOGIN_USER_HOME_DIR,upperdir=${TARGET_ROOTFS}/user_data/upperdir,workdir=${TARGET_ROOTFS}/user_data/workdir,index=off,metacopy=off,xino=off,redirect_dir=off overlay "$AUTOLOGIN_USER_HOME_DIR"

sudo -u $AUTOLOGIN_USERNAME openssl genrsa -out "$AUTOLOGIN_USER_HOME_DIR/.config/tls.key" 2048
sudo -u $AUTOLOGIN_USERNAME openssl req -new -key "$AUTOLOGIN_USER_HOME_DIR/.config/tls.key" -out "$AUTOLOGIN_USER_HOME_DIR/.config/tls.csr" -subj "/C=IT/ST=Veneto/L=Mestrino/O=MITEC Elettronica s.r.l./OU=SE/CN=mitec.it"
sudo -u $AUTOLOGIN_USERNAME openssl x509 -req -days 36500 -signkey "$AUTOLOGIN_USER_HOME_DIR/.config/tls.key" -in "$AUTOLOGIN_USER_HOME_DIR/.config/tls.csr" -out "$AUTOLOGIN_USER_HOME_DIR/.config/tls.crt"
rm "$AUTOLOGIN_USER_HOME_DIR/.config/tls.csr"

umount $AUTOLOGIN_USER_HOME_DIR

# add groups to be able to render the GUI application
usermod -aG render $AUTOLOGIN_USERNAME
usermod -aG video $AUTOLOGIN_USERNAME
usermod -aG audio $AUTOLOGIN_USERNAME
usermod -aG seat $AUTOLOGIN_USERNAME
usermod -aG input $AUTOLOGIN_USERNAME
usermod -aG tty $AUTOLOGIN_USERNAME

if "${LNG_CTL}" -u "${AUTOLOGIN_USERNAME}" -p "${AUTOLOGIN_MAIN_PASSWORD}" setup -i "${AUTOLOGIN_INTERMEDIATE_KEY}"; then
    if "${LNG_CTL}" -u "${AUTOLOGIN_USERNAME}" add --name "autologin" --intermediate "${AUTOLOGIN_INTERMEDIATE_KEY}" password --secondary-pw ""; then
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

    if ! "${LNG_CTL}" -u "${AUTOLOGIN_USERNAME}" set-home-mount --device "overlay" --fstype "overlay" --flags "lowerdir=/home/user,upperdir=${TARGET_ROOTFS}/user_data/upperdir,workdir=${TARGET_ROOTFS}/user_data/workdir,index=off,metacopy=off,xino=off,redirect_dir=off"; then
        echo "Error setting the user home mount"
        exit -1
    fi

    # Create the service directory
    readonly LOGIN_CFG_DIR="etc/polyauth"
    if ! mkdir -p "${EXTRACTED_ROOTFS_HOST_PATH}/${LOGIN_CFG_DIR}"; then
        echo "Error in creating ${EXTRACTED_ROOTFS_HOST_PATH}/${LOGIN_CFG_DIR}/"
        exit -1
    fi

    # Authorize the mount
    AUTOLOGIN_USER_MOUNTS_HASH=$("${LNG_CTL}" -u "${AUTOLOGIN_USERNAME}" inspect | awk '/hash:/ {print $3}')
    AUTOLOGIN_USER_MOUNTS_HASH_GET_RESULT=$?
    if [ $AUTOLOGIN_USER_MOUNTS_HASH_GET_RESULT -eq 0 ]; then
        echo ""
        echo ""
        echo "---------------- Authorized Mounts -----------------------"
        echo "{" | tee "${EXTRACTED_ROOTFS_HOST_PATH}/${LOGIN_CFG_DIR}/authorized_mounts.json"
        echo "    \"authorizations\": {" | tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/${LOGIN_CFG_DIR}/authorized_mounts.json"
        echo "        \"${AUTOLOGIN_USERNAME}\": [" | tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/${LOGIN_CFG_DIR}/authorized_mounts.json"
        echo "            \"${AUTOLOGIN_USER_MOUNTS_HASH}\"" | tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/${LOGIN_CFG_DIR}/authorized_mounts.json"
        echo "        ]" | tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/${LOGIN_CFG_DIR}/authorized_mounts.json"
        echo "    }" | tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/${LOGIN_CFG_DIR}/authorized_mounts.json"
        echo "}" | tee -a "${EXTRACTED_ROOTFS_HOST_PATH}/${LOGIN_CFG_DIR}/authorized_mounts.json"
        echo "----------------------------------------------------------"
        echo ""
        echo ""
        echo "----------------- Autologin Review -----------------------"
        "${LNG_CTL}" -u "${AUTOLOGIN_USERNAME}" inspect
        echo "----------------------------------------------------------"
    else
        echo "Error fetching autologin user's mounts"
        exit -1
    fi
else
    echo "Error setting up the user login data"
    exit -1
fi

# set the default autologin command
sed -i -e "s|/usr/bin/login_ng-cli|/usr/bin/login_ng-cli -u ${AUTOLOGIN_USERNAME} -c $AUTOLOGIN_CMD|" "${EXTRACTED_ROOTFS_HOST_PATH}/etc/greetd/config.toml"

# Change permissions to what is in home folder
chown -R ${AUTOLOGIN_UID}:${AUTOLOGIN_GID} "${AUTOLOGIN_USER_HOME_DIR}"

# The script won't be re-run
rm -rf "/etc/autologin"

sync
