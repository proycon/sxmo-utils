#!/bin/sh

stop_idle() {
	kill "$IDLEPID"
}

start_idle() {
	sxmo_idle.sh \
		timeout 8 'sxmo_screenlock_deeper.sh --idle' \
		timeout 10 "busybox kill -USR1 $$" &
	IDLEPID=$!
}

restart_idle() {
	stop_idle
	start_idle
	wait "$IDLEPID"
}

trap 'restart_idle' USR1
trap 'stop_idle' TERM INT

start_idle
wait "$IDLEPID"
