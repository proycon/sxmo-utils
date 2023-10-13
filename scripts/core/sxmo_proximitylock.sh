#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

# This hook enables the proximity lock.

finish() {
	kill "$EVENTMONITORPID"
	kill "$TAILPID"
	rm "$tmp"

	# De-activate thresholds
	printf 0 > "$prox_path/events/in_proximity_thresh_falling_value"
	# The in_proximity_scale affects the maximum threshold value
	# (see static const int stk3310_ps_max[4])
	printf 6553 > "$prox_path/events/in_proximity_thresh_rising_value"

	sxmo_wakelock.sh unlock sxmo_proximity_lock_running

	if [ -n "$INITIALSTATE" ]; then
		sxmo_state.sh set "$INITIALSTATE"
	fi

	exit
}

near() {
	if [ -z "$INITIALSTATE" ]; then
		INITIALSTATE="$(cat "$SXMO_STATE")"
	fi

	sxmo_debug "near"
	sxmo_state.sh set screenoff
}

far() {
	if [ -z "$INITIALSTATE" ]; then
		INITIALSTATE="$(cat "$SXMO_STATE")"
	fi

	sxmo_debug "far"
	sxmo_state.sh set unlock
}

trap 'finish' TERM INT

sxmo_wakelock.sh lock sxmo_proximity_lock_running infinite

# find the device
if [ -z "$SXMO_PROX_RAW_BUS" ]; then
	prox_raw_bus="$(find /sys/devices/platform -name 'in_proximity_raw' | head -n1)"
else
	prox_raw_bus="$SXMO_PROX_RAW_BUS"
fi
prox_path="$(dirname "$prox_raw_bus")"
prox_name="$(cat "$prox_path/name")" # e.g. stk3310

# set some sane defaults
printf "%d" "${SXMO_PROX_FALLING:-50}" > "$prox_path/events/in_proximity_thresh_falling_value"
printf "%d" "${SXMO_PROX_RISING:-100}" > "$prox_path/events/in_proximity_thresh_rising_value"

tmp="$(mktemp)"

# TODO: stdbuf not needed with linux-tools-iio >=5.17
stdbuf -o L iio_event_monitor "$prox_name" >> "$tmp" &
EVENTMONITORPID=$!

tail -f "$tmp" | while read -r line; do
	if echo "$line" | grep -q rising; then
		near
	elif echo "$line" | grep -q falling; then
		far
	fi
done &
TAILPID=$!

initial_distance="$(cat "$prox_raw_bus")"
if [ "$initial_distance" -gt "${SXMO_PROX_FALLING:-50}" ]; then
	near
elif [ "$initial_distance" -lt "${SXMO_PROX_RISING:-100}" ]; then
	far
fi

wait

finish
