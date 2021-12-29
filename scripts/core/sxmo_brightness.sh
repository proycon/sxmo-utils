#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

notify() {
	case "$SXMO_WM" in
		sway)
			light | grep -o "^[0-9]*" > "$XDG_RUNTIME_DIR"/sxmo.wobsock
			;;
		*)
			light | xargs notify-send " Brightness"
			;;
	esac
}

setvalue() {
	light -S "$1"
}

up() {
	light -A 5
}

down() {
	light -N 5
	light -U 5
}

getvalue() {
	light
}

"$@"
notify
