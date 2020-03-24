#!/usr/bin/env sh
OLDB=$(cat /tmp/oldscreenb || echo 10)
DIMB=2
CURB=$(cat /sys/devices/platform/backlight/backlight/backlight/brightness)

[[ $CURB == $DIMB ]] && sxmo_setpinebacklight $OLDB || sxmo_setpinebacklight $DIMB
