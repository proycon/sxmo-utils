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
	sxmo_statusbarupdate.sh
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
mute() {
        echo "$(sxmo_audiocurrentdevice.sh)" > /tmp/muted-audio.dev
	amixer set "$(cat /tmp/muted-audio.dev)" mute
	notify
}
unmute() {
	amixer set "$(cat /tmp/muted-audio.dev)" unmute
	notify
}

"$@"
