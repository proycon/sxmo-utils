#!/bin/sh

# This script is executed as root
# from the init process and sets
# some device-specific permissions

if [ -e /sys/firmware/devicetree/base/compatible ]; then
	device="$(cut -d ',' -f 2 < /sys/firmware/devicetree/base/compatible | tr -d '\0')"
	deviceprofile="$(which "sxmo_deviceprofile_$device.sh")"
	# shellcheck disable=SC1090
	[ -f "$deviceprofile" ] && . "$deviceprofile"
fi

# the defaults are best guesses
# users can override this in sxmo_deviceprofile_mydevice.sh
files="${SXMO_SYS_FILES:-"/sys/power/state /sys/power/mem_sleep /sys/bus/usb/drivers/usb/unbind /sys/bus/usb/drivers/usb/bind /dev/rtc0"}"

for file in $files; do
    [ -e "$file" ] && chmod a+rw "$file"
done

chmod -R a+rw /sys/class/wakeup/*
