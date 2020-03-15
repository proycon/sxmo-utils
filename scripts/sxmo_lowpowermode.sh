#!/usr/bin/env sh
TOUCHSCREENID=$(
	xinput | 
	grep -i touchscreen | 
	grep pointer | 
	grep -oE 'id=[0-9]+' | 
	cut -d= -f2
)

xinput disable $TOUCHSCREENID
sxmo_setpineled blue 1
OLDB="$(cat /sys/class/backlight/backlight/brightness)"
sxmo_setpinebacklight 0
echo "Dragons?" | dmenu

sxmo_setpinebacklight $OLDB
sxmo_setpineled blue 0
xinput enable $TOUCHSCREENID
