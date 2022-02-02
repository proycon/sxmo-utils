#!/bin/sh

export SXMO_SPEAKER="Speaker"
export SXMO_HEADPHONE="Headphone"
export SXMO_EARPIECE="Earpiece"
export BACKLIGHT="/sys/devices/platform/backlight-dsi/backlight/backlight-dsi"
export LED_RED_TYPE="status"
export LED_GREEN_TYPE="status"
export LED_BLUE_TYPE="status"
export LED_WHITE_TYPE="torch"
export SXMO_SYS_FILES="/sys/power/state /sys/power/mem_sleep /sys/bus/usb/drivers/usb/unbind /sys/bus/usb/drivers/usb/bind /dev/rtc0"
