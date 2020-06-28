#!/usr/bin/env sh
[ -e /sys/class/backlight/edp-backlight ] && DEV=/sys/class/backlight/edp-backlight
[ -e /sys/devices/platform/backlight/backlight/backlight ] && DEV=/sys/devices/platform/backlight/backlight/backlight

MAX=$(cat $DEV/max_brightness)
MIN=2
MINSTEP=1
STEP=$(echo "($MAX - $MIN) / 10" | bc | xargs -ISTP echo -e "$MINSTEP\nSTP" | sort -r | head -n1)

setdelta() {
	sxmo_setpinebacklight "$(
		xargs -IB echo B "$1" < $DEV/brightness |
		bc |
		xargs -INUM echo -e "$MIN\nNUM" | sort -n | tail -n1 |
		xargs -INUM echo -e "$MAX\nNUM" | sort -n | head -n1
	)"

	dunstify -i 0 -u normal -r 999 "☀ $(cat $DEV/brightness)/${MAX}"
}

up() {
	setdelta "+${STEP}"
}

down() {
	setdelta "-${STEP}"
}

"$@"
