#!/usr/bin/env sh

RUNNING_AUTO="$(ps aux | grep "sh /usr/bin/sxmo_autorotate.sh" | grep -v grep | cut -f1 -d' ' | grep -v "$$")"

[ "$(echo "$RUNNING_AUTO" | wc -l)" -ge "2" ] && echo "$RUNNING_AUTO" | tr '\n' ' ' | xargs kill -9 
[ "$(echo "$RUNNING_AUTO" | wc -l)" -ge "2" ] && notify-send "Turning autorotate off" && exit 1

notify-send "Turning autorotate on"

GRAVITY="16374"
THRESHOLD="400"
POLL_TIME=1

RIGHT_SIDE_UP="$(echo "$GRAVITY - $THRESHOLD" | bc)"
UPSIDE_DOWN="$(echo "-$GRAVITY + $THRESHOLD" | bc)"
y_file="$(find /sys/bus/iio/devices/iio\:device*/ -iname in_accel_y_raw)"
x_file="$(find /sys/bus/iio/devices/iio\:device*/ -iname in_accel_x_raw)"

while :
do

	y_raw="$(cat "$y_file")"
	x_raw="$(cat "$x_file")"

	if  [ "$x_raw" -ge "$RIGHT_SIDE_UP" ]
	then
		sxmo_rotate.sh rotnormal
	elif [ "$y_raw" -le "$UPSIDE_DOWN" ]
	then
		sxmo_rotate.sh rotright
	elif [ "$y_raw" -ge "$RIGHT_SIDE_UP" ]
	then
		sxmo_rotate.sh rotleft
	fi
	sleep "$POLL_TIME"
done
