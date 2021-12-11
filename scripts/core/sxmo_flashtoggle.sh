#!/bin/sh
sxmo_setled.sh white "$(
	grep -qE '^0$' /sys/class/leds/white:flash/brightness &&
	echo 255 || echo 0
)"

