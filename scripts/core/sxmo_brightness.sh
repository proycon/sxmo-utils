#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

BACKLIGHT="${BACKLIGHT:-/sys/devices/platform/backlight/backlight/backlight}"
if [ ! -e "$BACKLIGHT" ] && [ -e /sys/class/backlight/edp-backlight ]; then
	BACKLIGHT=/sys/class/backlight/edp-backlight
fi

[ ! -e "$BACKLIGHT" ] && echo "unable to find backlight device" && exit 1

MAX=$(cat $BACKLIGHT/max_brightness)
MIN=2
MINSTEP=1
STEP=$(echo "($MAX - $MIN) / 10" | bc | xargs -ISTP echo -e "$MINSTEP\nSTP" | sort -r | head -n1)

setdelta() {
	sxmo_setpinebacklight "$(
		xargs -IB echo B "$1" < $BACKLIGHT/brightness |
		bc |
		xargs -INUM echo -e "$MIN\nNUM" | sort -n | tail -n1 |
		xargs -INUM echo -e "$MAX\nNUM" | sort -n | head -n1
	)"

	dunstify -i 0 -u normal -r 999 "☀ $(cat $BACKLIGHT/brightness)/${MAX}"
}

up() {
	setdelta "+${STEP}"
}

down() {
	setdelta "-${STEP}"
}

"$@"
