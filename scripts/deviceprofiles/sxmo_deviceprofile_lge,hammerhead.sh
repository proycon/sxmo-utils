#!/bin/sh
# LG Nexus 5

export SXMO_DISABLE_LEDS="1" # Not supported by kernel (as of 5.16).
export SXMO_MIN_BRIGHTNESS="4" # Screen turns off below 4.
export SXMO_POWER_BUTTON="0:0:pm8941_pwrkey"
export SXMO_VOLUME_BUTTON="1:1:gpio-keys"

export SXMO_SWAY_SCALE="2"

# export SXMO_TOUCHSCREEN_ID="" # TODO for xorg support.
