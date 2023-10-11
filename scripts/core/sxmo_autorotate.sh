#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

ROTATION_GRAVITY="${SXMO_ROTATION_GRAVITY:-"16374"}"
ROTATION_THRESHOLD="${SXMO_ROTATION_THRESHOLD:-"400"}"
POLL_TIME="${SXMO_ROTATION_POLL_TIME:-1}"
RIGHT_SIDE_UP="$(echo "$ROTATION_GRAVITY - $ROTATION_THRESHOLD" | bc)"
UPSIDE_DOWN="$(echo "-$ROTATION_GRAVITY + $ROTATION_THRESHOLD" | bc)"
FILE_Y="$(find /sys/bus/iio/devices/iio:device*/ -iname in_accel_y_raw)"
FILE_X="$(find /sys/bus/iio/devices/iio:device*/ -iname in_accel_x_raw)"

while true; do
	y_raw="$(cat "$FILE_Y")"
	x_raw="$(cat "$FILE_X")"
	if  [ "$x_raw" -ge "$RIGHT_SIDE_UP" ] && sxmo_rotate.sh isrotated ; then
		sxmo_rotate.sh rotnormal
	elif [ "$x_raw" -le "$UPSIDE_DOWN" ] && [ "$(sxmo_rotate.sh isrotated)" != "invert" ]; then
		sxmo_rotate.sh rotinvert
	elif [ "$y_raw" -le "$UPSIDE_DOWN" ] && [ "$(sxmo_rotate.sh isrotated)" != "right" ]; then
		sxmo_rotate.sh rotright
	elif [ "$y_raw" -ge "$RIGHT_SIDE_UP" ] && [ "$(sxmo_rotate.sh isrotated)" != "left" ]; then
		sxmo_rotate.sh rotleft
	fi
	sleep "$POLL_TIME"
done
