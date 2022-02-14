#!/bin/sh
# Pine Note!

# from https://github.com/DorianRudolph/pinenotes
export WLR_RENDERER_ALLOW_SOFTWARE=1 # Dorian
export GALLIUM_DRIVER=llvmpipe # Dorian
export LIBGL_ALWAYS_SOFTWARE=true

export SXMO_TOUCHSCREEN_ID="10"
export SXMO_STYLUS_ID="12"
export SXMO_DISABLE_LEDS="1"
export SXMO_WAKEUPRTC="2"
export SXMO_MODEMRTC="9999" # we don't have one of course
export SXMO_POWERRTC="5" # same as pinephone
export SXMO_COVERRTC="8" 
export SXMO_MIN_BRIGHTNESS="0" # we can set brightness all the way down
export SXMO_SYS_FILES="/sys/power/state /sys/power/mem_sleep /sys/bus/usb/drivers/usb/unbind /sys/bus/usb/drivers/usb/bind /dev/rtc0"
export SXMO_BMENU_LANDSCAPE_LINES="15"
export SXMO_MONITOR="Unknown-1"
export SXMO_POWER_BUTTON="0:0:rk805_pwrkey"
export SXMO_VOLUME_BUTTON="none"
export SXMO_ROTATION_POLL_TIME="0" # the device already polls at 1s so a further 1s poll is pointless
export SXMO_UNLOCK_IDLE_TIME="30"
export SXMO_SPEAKER="Master"
