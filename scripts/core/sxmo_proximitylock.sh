#!/usr/bin/env sh

finish() {
	kill $(jobs -p)
	[ free = "$STATE" ] && [ true = "$WASLOCKED" ] && sxmo_lock.sh &
	exit 0
}

trap 'finish' TERM INT

proximity_raw_bus="$(find /sys/ -name 'in_proximity_raw')"
distance() {
	cat "$proximity_raw_bus"
}

TARGET=30

mainloop() {
	while true; do
		distance="$(distance)"
		if [ locked = "$STATE" ] && [ "$distance" -lt "$TARGET" ]; then
			pkill -f sxmo_lock.sh
			STATE=free
		elif [ free = "$STATE" ] && [ "$distance" -gt "$TARGET" ]; then
			sxmo_lock.sh --screen-off &
			STATE=locked
		fi
		sleep 0.5
	done
}

pgrep -f sxmo_lock.sh > /dev/null && STATE=locked || STATE=free
if [ locked = "$STATE" ]; then
	WASLOCKED=true

	# we dont want to loose the initial lock if the phone is forgotten somewhere
	# without proximity as this will prevent going back to crust
	sxmo_movement.sh waitmovement
fi

mainloop
