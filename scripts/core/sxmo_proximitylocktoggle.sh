#!/usr/bin/env sh

proximitylockdisable() {
	notify-send "Proximity Lock Disabled"
	pkill -f "$(command -v sxmo_proximitylock.sh)"
	exit 0
}

proximitylockenable() {
	notify-send "Proximity Lock Enabled"
	setsid -f sxmo_proximitylock.sh &
}

if pgrep -f "$(command -v sxmo_proximitylock.sh)"; then
	proximitylockdisable
else
	proximitylockenable
fi
