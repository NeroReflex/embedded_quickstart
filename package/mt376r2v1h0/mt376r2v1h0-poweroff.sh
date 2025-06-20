#!/bin/sh

if [ -d "/sys/class/backlight/backlight/" ]; then
    echo 0 > /sys/class/backlight/backlight/brightness
else
    echo "WARNING: brightness control unavailable"
fi
