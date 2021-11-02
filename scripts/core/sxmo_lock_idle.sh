#!/bin/sh

stop_idle() {
	kill "$IDLEPID"
	unset IDLEPID
}

start_idle() {
	sxmo_idle.sh \
		timeout 8 'sxmo_screenlock_deeper.sh --idle' \
		timeout 16 'sxmo_screenlock_deeper.sh --idle' &
	IDLEPID=$!
}

restart_idle() {
	stop_idle
	start_idle
}

finish() {
	stop_idle
	exit
}

trap 'finish' TERM INT
trap 'restart_idle' USR1

while : ; do
	if sxmo_hooks.sh is_idle; then
		if [ -z "$IDLEPID" ]; then
			start_idle
		fi
	else
		if [ -n "$IDLEPID" ]; then
			stop_idle
		fi
	fi
	sleep 30 & wait $! # We dont want to delay signal catches
done
