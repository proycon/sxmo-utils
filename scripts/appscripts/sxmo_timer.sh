#!/usr/bin/env sh
timerrun() {
	TIME=$(
		echo "$@" |
		sed 's#h#*60m#g'|
		sed 's#m#*60s#g'|
		sed 's#s#*1#g'|
		sed 's# #+#g' |
		bc
	)

	DATE1=$(($(date +%s) + TIME));
	while [ "$DATE1" -ge "$(date +%s)" ]; do
		printf %b "$(date -u --date @$((DATE1 - $(date +%s))) +%H:%M:%S) \r";
		sleep 0.1
	done
	echo "Done with $*"

	while :;
		do notify-send  "Done with $*";
		sxmo_vibratepine 1000
		sleep 0.5
	done
}

menu() {
	pidof "$KEYBOARD" || "$KEYBOARD" &
	TIMEINPUT="$(
	echo "
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
	" | awk 'NF' | awk '{$1=$1};1' | dmenu -p Timer -c -fn "Terminus-30" -l 20
	)"
	pkill "$KEYBOARD"
	[ "Close Menu" = "$TIMEINPUT" ] && exit 0
	st -f Monospace-50 -e "$0" timerrun "$TIMEINPUT"
}

if [ $# -gt 0 ]; then "$@"; else menu; fi
