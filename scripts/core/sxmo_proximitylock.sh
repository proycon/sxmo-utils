#!/bin/sh

isLocked() {
	curState="$(sxmo_screenlock.sh getCurState)"
	[ "$curState" = "lock" ] || [ "$curState" = "off" ]
}

finish() {
	MUTEX_NAME=can_suspend sxmo_mutex.sh free "Proximity lock is running"
	sxmo_screenlock.sh "$INITIALSTATE"
	exit 0
}

INITIALSTATE="$(sxmo_screenlock.sh getCurState)"
trap 'finish' TERM INT

MUTEX_NAME=can_suspend sxmo_mutex.sh lock "Proximity lock is running"

proximity_raw_bus="$(find /sys/devices/platform/soc -name 'in_proximity_raw')"
distance() {
	cat "$proximity_raw_bus"
}

TARGET=30

mainloop() {
	while true; do
		distance="$(distance)"
		if isLocked && [ "$distance" -lt "$TARGET" ]; then
			sxmo_screenlock.sh unlock
		elif ! isLocked && [ "$distance" -gt "$TARGET" ]; then
			sxmo_screenlock.sh off
		fi
		sleep 0.5
	done
}

mainloop
