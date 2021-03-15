#!/usr/bin/env sh

# This script is executed as root
# from the init process and sets
# some device-specific permissions

DEVICE="unknown"

#Detecting device
if [ -e /sys/firmware/devicetree/base ]; then
    if grep -q pinephone compatible; then
        DEVICE="pinephone"
    fi
fi

pinephone_files="/sys/module/8723cs/parameters/rtw_scan_interval_thr /sys/power/state /sys/devices/platform/soc/1f00000.rtc/power/wakeup /sys/power/mem_sleep /sys/bus/usb/drivers/usb/unbind /sys/bus/usb/drivers/usb/bind /dev/rtc0 /sys/devices/platform/soc/1f03400.rsb/sunxi-rsb-3a3/axp221-pek/power/wakeup"

if [ "$DEVICE" = "pinephone" ]; then
    files="$pinephone_files"
else
    #guess a few that are hopefully fairly generic:
    files="/sys/power/state /sys/power/mem_sleep /sys/bus/usb/drivers/usb/unbind /sys/bus/usb/drivers/usb/bind /dev/rtc0"
    echo "Warning: SXMO is running on an unknown device, things may not work as expected!">&2
fi

for file in $files; do
    [ -e "$file" ] && chmod a+rw "$file"
done

chmod -R a+rw /sys/class/wakeup/*
