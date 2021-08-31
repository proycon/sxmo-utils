#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

notify() {
	light | xargs notify-send " Brightness"
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
