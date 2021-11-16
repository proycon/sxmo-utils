#!/bin/sh

_swayidletoidles() {
	while [ $# -gt 0 ]; do
		case "$1" in
			timeout)
				printf "%s|%s\n" "$2" "$3"
				shift 3
				;;
		esac
	done
}

xorgidle() {
	idles="$(_swayidletoidles "$@")"

	tick=0
	new_idle="$(xprintidle)"
	last_idle="$new_idle"

	while : ; do
		last_idle="$new_idle"
		new_idle="$(xprintidle)"
		if [ "$last_idle" -gt "$new_idle" ]; then
			tick=0
		fi

		printf "%b\n" "$idles" | \
			grep "^$tick|" | \
			cut -d'|' -f2- | \
			xargs -I{} -0 sh -c "{}"

		sleep 1
		tick=$((tick + 1))
	done
}

case "$SXMO_WM" in
	dwm) xorgidle "$@" & ;;
	*) "${SXMO_WM}idle" "$@" & ;;
esac
IDLEPID=$!

finish() {
	kill "$IDLEPID"
}
trap 'finish' TERM INT

wait "$IDLEPID"
