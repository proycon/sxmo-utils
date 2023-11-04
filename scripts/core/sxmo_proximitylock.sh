#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

# This hook enables the proximity lock.

finish() {
	sxmo_wakelock.sh unlock sxmo_proximity_lock_running

	if [ -n "$INITIALSTATE" ]; then
		sxmo_state.sh set "$INITIALSTATE"
	fi

	exit
}

near() {
	if [ -z "$INITIALSTATE" ]; then
		INITIALSTATE="$(sxmo_state.sh get)"
	fi

	sxmo_debug "near"
	sxmo_state.sh set screenoff
}

far() {
	if [ -z "$INITIALSTATE" ]; then
		INITIALSTATE="$(sxmo_state.sh get)"
	fi

	sxmo_debug "far"
	sxmo_state.sh set unlock
}

trap 'finish' TERM INT EXIT

sxmo_wakelock.sh lock sxmo_proximity_lock_running infinite

# find the device
if [ -z "$SXMO_PROX_RAW_BUS" ]; then
	prox_raw_bus="$(find /sys/devices/platform -name 'in_proximity_raw' | head -n1)"
else
	prox_raw_bus="$SXMO_PROX_RAW_BUS"
fi

while : ; do
	value="$(cat "$prox_raw_bus")"
	if [ "$value" -gt 100 ] && [ "$last" != "near" ]; then
		near
		last=near
	elif [ "$value" -lt 100 ] && [ "$last" != "far" ]; then
		far
		last=far
	fi
	sleep 0.5
done
