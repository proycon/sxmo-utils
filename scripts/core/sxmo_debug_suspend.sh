#! /bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2023 Sxmo Contributors

log() {
	# Copied from sxmo_common.sh for consistent formatting
	printf "%s: %s\n" "$(date +%H:%M:%S)" "$*"
}

finish() {
	if [ -n "$pid" ]; then
		kill "$pid"
	fi
	exit 0
}
trap 'finish' INT TERM EXIT

tail -f "${XDG_STATE_HOME:-$HOME}"/sxmo.log | grep sxmo_hook_block_suspend.sh &
pid=$!

while true; do
	locks="$(cat /sys/power/wake_lock 2>/dev/null)"
	if [ "$locks" != "$oldlocks" ]; then
		log "wakelocks: $locks"
		oldlocks="$locks"
	fi
	sleep 1;
done

wait
