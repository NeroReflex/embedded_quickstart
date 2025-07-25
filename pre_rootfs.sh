#!/bin/bash

readonly CURRENT_SCRIPT_DIR="${BASH_SOURCE%/*}"

if [ -f "${TARGET_DIR}/usr/share/factory/etc/pam.d/system-auth" ] && [ ! -f "${TARGET_DIR}/etc/pam.d/system-auth" ]; then
    # I have absolutely no idea why this should be even needed... But it is. ffs.
    cp "${CURRENT_SCRIPT_DIR}/pam_example/system-auth" "${TARGET_DIR}/etc/pam.d/system-auth"
fi

for file in /etc/pam.d/*; do
    pam_selinux_location=$(find "${TARGET_DIR}/usr" -name "pam_selinux.so")
    if [ -z "$pam_selinux_location" ]; then
        if [ -f "$file" ]; then
            sed -i '/pam_selinux.so/s/^/#/' "$file"
        fi
    fi

    pam_console_location=$(find "${TARGET_DIR}/usr" -name "pam_console.so")
    if [ -z "$pam_console_location" ]; then
        if [ -f "$file" ]; then
            sed -i '/pam_console.so/s/^/#/' "$file"
        fi
    fi
done

touch "${TARGET_DIR}/etc/pam_debug"

echo "${TARGET_DIR}"