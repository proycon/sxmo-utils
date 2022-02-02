#!/bin/sh

# This script is executed as root
# from the init process and sets
# some device-specific permissions

device="$(cut -d ',' -f 2 < /sys/firmware/devicetree/base/compatible | tr -d '\0')"
deviceprofile="$(which "sxmo_deviceprofile_$device.sh")"
# shellcheck disable=SC1090
[ -f "$deviceprofile" ] && . "$deviceprofile"

# the defaults are pinephone
# users can override this in sxmo_deviceprofile_mydevice.sh
files="${SXMO_SYS_FILES:-"/sys/module/8723cs/parameters/rtw_scan_interval_thr /sys/power/state /sys/devices/platform/soc/1f00000.rtc/power/wakeup /sys/power/mem_sleep /sys/bus/usb/drivers/usb/unbind /sys/bus/usb/drivers/usb/bind /dev/rtc0 /sys/devices/platform/soc/1f03400.rsb/sunxi-rsb-3a3/axp221-pek/power/wakeup"}"

for file in $files; do
    [ -e "$file" ] && chmod a+rw "$file"
done

chmod -R a+rw /sys/class/wakeup/*
