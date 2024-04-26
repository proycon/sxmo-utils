#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

cleanly_quit() {
	kill $BGPROC
}

# check if iio-sensor-proxy found a proximity sensor
gdbus call --system --dest net.hadess.SensorProxy \
	   --object-path /net/hadess/SensorProxy \
	   --method org.freedesktop.DBus.Properties.Get \
	net.hadess.SensorProxy HasAccelerometer  | grep -q 'true' || exit

trap 'cleanly_quit' INT TERM EXIT

monitor-sensor --accel | while read -r line; do
	# first line checks if iio-sensor-proxy is running
	echo "$line" | grep -qi 'waiting' && continue
	# second line confirms iio-sensor-proxy is running
	echo "$line" | grep -qi 'appeared' && continue
	# read orientation
	orientation=$(echo "$line" | cut -d ':' -f 2)
	case "$orientation" in
		# on the very first sensor claim, the orientation might be
		# reported as "undefined." assume "normal" in that case
		*"undefined"*|*"normal"*)
			sxmo_rotate.sh rotnormal
			;;
		*"bottom-up"*)
			sxmo_rotate.sh rotinvert
			;;
		*"left-up"*)
			sxmo_rotate.sh rotleft
			;;
		*"right-up"*)
			sxmo_rotate.sh rotright
			;;
	esac
done &
BGPROC=$?
wait
