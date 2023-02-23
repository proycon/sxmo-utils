#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

usage() {
		cat >&2 <<EOF
Usage: $(basename "$0") ACTION
	lock <lock-name> <nanosec|infinite>
	unlock <lock-name>
EOF
}

lock() {
	if [ "$#" -ne 2 ]; then
		usage
		exit 1
	fi

	if [ ! -f /sys/power/wake_lock ]; then
		exit # we swallow when the system doesn't support it
	fi

	if [ "$2" = "infinite" ]; then
		sxmo_debug "lock $1 infinite"
		echo "$1" | doas tee -a /sys/power/wake_lock > /dev/null
		exit
	fi

	if [ "$2" -ne "$2" ]; then
		echo "$2 isn't a duration" >&2
		exit 1
	fi

	sxmo_debug "lock $1 $2"
	echo "$1 $2" | doas tee -a /sys/power/wake_lock > /dev/null
}

unlock() {
	if [ "$#" -ne 1 ]; then
		usage
		exit 1
	fi

	if [ ! -f /sys/power/wake_unlock ]; then
		exit # we swallow when the system doesn't support it
	fi

	sxmo_debug "unlock $1"
	echo "$1" | doas tee -a /sys/power/wake_unlock > /dev/null 2>&1
}

debug() {
	tr " " "\n" < /sys/power/wake_lock | grep .
	tail -f "$XDG_STATE_HOME"/sxmo.log | grep "${0##*/}"
}

cmd="$1"
shift
case "$cmd" in
	lock) lock "$@";;
	unlock) unlock "$@";;
	debug) debug "$@";;
	*) usage; exit 1;;
esac
