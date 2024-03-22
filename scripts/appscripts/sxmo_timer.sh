#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors
# title="$icon_clk Timer"
# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

_finish_timerrun() {
	_releasealarm
	exit
}

_setupalarm() {
	sxmo_sleep -c boottime_alarm "$1" &
	alarmpid=$!
}

_releasealarm() {
	if [ -n "$alarmpid" ]; then
		kill "$alarmpid" 2> /dev/null
		unset alarmpid
	fi
}

timerrun() {
	trap '_finish_timerrun' INT TERM EXIT

	TIME="$(
		echo "$@" |
		sed 's/\([^0-9]\)\([0-9]\)/\1+\2/g; s/h/*60m/g; s/m/*60s/g; s/s//g' |
		bc
	)"

	_setupalarm "$TIME"

	DATE1="$(($(date +%s) + TIME))";
	while [ "$DATE1" -gt "$(date +%s)" ]; do
		printf "%s\r" "$(date -u --date @$((DATE1 - $(date +%s))) +%H:%M:%S)";
		sxmo_aligned_sleep 1
	done
	echo "Done with $*"

	_releasealarm

	while : ;
		do notify-send  "Done with $*";
		sxmo_vibrate 1000 "${SXMO_VIBRATE_STRENGTH:-1}"
		sleep 0.5
	done
}

stopwatchrun() {
	start="$(date +%s)"
	while : ; do
		time="$(($(date +%s) - start))"
		printf '%s\r' "$(date -u -d "@$time" +%H:%M:%S)"
		sxmo_aligned_sleep 1
	done
}

menu() {
	TIMEINPUT="$(sxmo_dmenu.sh -p Timer <<EOF
Stopwatch
1h
10m
9m
8m
7m
6m
5m
4m
3m
2m
1m
30s
Close Menu
EOF
	)" || exit
	case "$TIMEINPUT" in
		"Close Menu")
			exit 0
			;;
		"Stopwatch")
			sxmo_terminal.sh "$0" stopwatchrun
			;;
		*)
			sxmo_terminal.sh "$0" timerrun "$TIMEINPUT"
			;;
	esac
}

if [ $# -gt 0 ]
then
	"$@"
else
	menu
fi
