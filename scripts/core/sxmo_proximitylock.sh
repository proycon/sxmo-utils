#!/bin/sh

isLocked() {
	! grep -q unlock "$SXMO_STATE"
}

finish() {
	sxmo_mutex.sh can_suspend free "Proximity lock is running"
	sxmo_hooks.sh "$INITIALSTATE"
	exit 0
}

INITIALSTATE="$(cat "$SXMO_STATE")"
trap 'finish' TERM INT

sxmo_mutex.sh can_suspend lock "Proximity lock is running"

proximity_raw_bus="$(find /sys/devices/platform/soc -name 'in_proximity_raw')"
distance() {
	cat "$proximity_raw_bus"
}

TARGET=30

mainloop() {
	while true; do
		distance="$(distance)"
		if isLocked && [ "$distance" -lt "$TARGET" ]; then
			sxmo_hooks.sh unlock
		elif ! isLocked && [ "$distance" -gt "$TARGET" ]; then
			sxmo_hooks.sh screenoff
		fi
		sleep 0.5
	done
}

mainloop
