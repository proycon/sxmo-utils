#!/bin/sh
# Pine Note!

export SXMO_TOUCHSCREEN_ID="10"
export SXMO_STYLUS_ID="12"
export SXMO_DISABLE_LEDS="1"
export SXMO_WAKEUPRTC="2"
#export SXMO_MODEMRTC="" # we don't have one of course
#export SXMO_POWERRTC="5" # same as pinephone
export SXMO_SPEAKER="Master"
export SXMO_MIN_BRIGHTNESS="0" # we can set brightness all the way down
export SXMO_SYS_FILES="/sys/power/state /sys/power/mem_sleep /sys/bus/usb/drivers/usb/unbind /sys/bus/usb/drivers/usb/bind /dev/rtc0"
export SXMO_BMENU_LANDSCAPE_LINES="15"
export SXMO_MONITOR="Unknown-1"
export SXMO_POWER_BUTTON="0:0:rk805_pwrkey"
export SXMO_VOLUME_BUTTON="none"
export SXMO_ROTATION_POLL_TIME="0" # the device already polls at 1s so a further 1s poll is pointless
export SXMO_UNLOCK_IDLE_TIME="300"
export SXMO_DUMB_LOCK="1" # only two states: unlock and crust
