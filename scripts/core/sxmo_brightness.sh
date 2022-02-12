#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

notify() {
	if [ "$SXMO_WM" = "sway" ] && [ -z "$SXMO_WOB_DISABLE" ]; then
		light | grep -o "^[0-9]*" > "$XDG_RUNTIME_DIR"/sxmo.wobsock
	else
		light | xargs dunstify -r 888 " Brightness"
	fi
}

setvalue() {
	light -S "$1"
}

up() {
	light -A 5
}

down() {
	light -N "${SXMO_MIN_BRIGHTNESS:-5}"
	light -U 5
}

getvalue() {
	light
}

"$@"
notify
