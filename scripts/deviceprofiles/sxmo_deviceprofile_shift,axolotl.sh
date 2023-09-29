#!/bin/sh
# shiftphone shift6mq
export SXMO_POWER_BUTTON="0:0:pm8941_pwrkey"
export SXMO_VOLUME_BUTTON="1:1:gpio-keys 0:0:pm8941_resin"
export SXMO_SWAY_SCALE="2.5"
export SXMO_VIBRATE_DEV="/dev/input/by-path/platform-c440000.spmi-platform-c440000.spmi:pmic@3:haptics@c000-event"
