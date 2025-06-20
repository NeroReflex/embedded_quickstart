#!/bin/sh

if [ -d "/sys/class/backlight/backlight/" ]; then
    if [ -f "/tmp/brightness" ]; then 
        cat /tmp/brightness > /sys/class/backlight/backlight/brightness
    else
        echo "ERROR: unsaved backlight"
        exit 1
    fi
else
    echo "WARNING: brightness control unavailable"
fi
