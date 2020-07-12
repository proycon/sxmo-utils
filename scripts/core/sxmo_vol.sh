#!/usr/bin/env sh
notify() {
	VOL="$(
		amixer get "$(sxmo_audiocurrentdevice.sh)" | 
		grep -oE '([0-9]+)%' |
		tr -d ' %' |
		awk '{ s += $1; c++ } END { print s/c }'  |
		xargs printf %.0f
	)"
	dunstify -i 0 -u normal -r 998 "♫ $VOL"
	pgrep -f "$(command -v sxmo_statusbar.sh)" | xargs kill -USR1
}

up() {
	amixer set "$(sxmo_audiocurrentdevice.sh)" 1+
	notify
}
down() {
	amixer set "$(sxmo_audiocurrentdevice.sh)" 1-
	notify
}
setvol() {
	amixer set "$(sxmo_audiocurrentdevice.sh)" "$1"
}

$1
