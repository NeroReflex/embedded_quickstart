#!/bin/bash
if [ -f "${TARGET_DIR}/usr/share/factory/etc/pam.d/system-auth" ] && [ ! -f "${TARGET_DIR}/etc/pam.d/system-auth" ]; then
    # I have absolutely no idea why this should be even needed... But it is. ffs.
    cp "${TARGET_DIR}/usr/share/factory/etc/pam.d/system-auth" "${TARGET_DIR}/etc/pam.d/system-auth"
fi

echo "${TARGET_DIR}"