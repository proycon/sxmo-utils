#!/usr/bin/env sh

islocked() {
	pgrep -f sxmo_lock.sh > /dev/null
}

syncstate() {
	islocked && STATE=locked || STATE=free
}

finish() {
	kill "$(jobs -p)"
	syncstate
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
		# here we do not syncstate to allow user manual lock
		if [ locked = "$STATE" ] && [ "$distance" -lt "$TARGET" ]; then
			pkill -f sxmo_lock.sh
			STATE=free
		elif [ free = "$STATE" ] && [ "$distance" -gt "$TARGET" ]; then
			islocked && pkill -f sxmo_lock.sh # we want screen-off on proximity
			sxmo_lock.sh --screen-off &
			STATE=locked
		fi
		sleep 0.5
	done
}

syncstate
if [ locked = "$STATE" ]; then
	WASLOCKED=true

	# we dont want to loose the initial lock if the phone is forgotten somewhere
	# without proximity as this will prevent going back to crust
	sxmo_movement.sh waitmovement
fi

mainloop
