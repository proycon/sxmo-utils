#!/usr/bin/env sh
GRAVITY="16374"
THRESHOLD="400"
POLL_TIME=1
RIGHT_SIDE_UP="$(echo "$GRAVITY - $THRESHOLD" | bc)"
UPSIDE_DOWN="$(echo "-$GRAVITY + $THRESHOLD" | bc)"
FILE_Y="$(find /sys/bus/iio/devices/iio:device*/ -iname in_accel_y_raw)"
FILE_X="$(find /sys/bus/iio/devices/iio:device*/ -iname in_accel_x_raw)"

autorotatedisable() {
	notify-send "Autorotate disabled"
	pgrep -f "$(command -v sxmo_rotateautotoggle.sh)" | grep -Ev "^${$}$" | xargs kill -9
	exit 0
}

autorotateenable() {
	notify-send "Autorotate enabled"
	while true; do
		y_raw="$(cat "$FILE_Y")"
		x_raw="$(cat "$FILE_X")"
		if  [ "$x_raw" -ge "$RIGHT_SIDE_UP" ]; then
			sxmo_rotate.sh rotnormal
		elif [ "$y_raw" -le "$UPSIDE_DOWN" ]; then
			sxmo_rotate.sh rotright
		elif [ "$y_raw" -ge "$RIGHT_SIDE_UP" ]; then
			sxmo_rotate.sh rotleft
		fi
		sleep "$POLL_TIME"
	done
}

if pgrep -f "$(command -v sxmo_rotateautotoggle.sh)" | grep -Ev "^${$}$"; then
	autorotatedisable
else
	autorotateenable
fi
