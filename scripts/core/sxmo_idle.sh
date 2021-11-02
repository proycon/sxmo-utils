#!/bin/sh

xorgidle() {
	tmp="$(mktemp)"
	while [ $# -gt 0 ]; do
		case "$1" in
			timeout)
				printf "%s|%s\n" "$2" "$3" >> "$tmp"
				shift 3
				;;
		esac
	done

	tick=0
	new_idle="$(xprintidle)"
	last_idle="$new_idle"

	while : ; do
		last_idle="$new_idle"
		new_idle="$(xprintidle)"
		if [ "$last_idle" -gt "$new_idle" ]; then
			tick=0
		fi

		while IFS='|' read -r second command; do
			if [ "$tick" -eq "$second" ]; then
				eval "$command"
			fi
		done < "$tmp"

		sleep 1
		tick=$((tick + 1))
	done &
}

wm="$(sxmo_wm.sh)"
case "$wm" in
	dwm|xorg) xorgidle "$@" & ;;
	*) "${wm}idle" "$@" & ;;
esac
IDLEPID=$!

finish() {
	kill "$IDLEPID"
}
trap 'finish' TERM INT

wait "$IDLEPID"
