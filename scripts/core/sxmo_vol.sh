#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

notify() {
	VOL="$(
		amixer get "$(sxmo_audiocurrentdevice.sh)" |
		grep -oE '([0-9]+)%' |
		tr -d ' %' |
		awk '{ s += $1; c++ } END { print s/c }'  |
		xargs printf %.0f
	)"
	case "$SXMO_WM" in
		sway)
			printf "%s\n" "$VOL" > "$XDG_RUNTIME_DIR"/sxmo.wobsock
			;;
		*)
			notify-send "♫ Volume" "$VOL"
			;;
	esac
	sxmo_statusbarupdate.sh vol
}

up() {
	amixer set "$(sxmo_audiocurrentdevice.sh)" 1%+
	notify
}
down() {
	amixer set "$(sxmo_audiocurrentdevice.sh)" 1%-
	notify
}
setvol() {
	amixer set "$(sxmo_audiocurrentdevice.sh)" "$1"%
	notify
}
mute() {
	sxmo_audiocurrentdevice.sh > /tmp/muted-audio.dev
	amixer set "$(cat /tmp/muted-audio.dev)" mute
	notify
}
unmute() {
	amixer set "$(cat /tmp/muted-audio.dev)" unmute
	notify
}

"$@"
