#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

detect_device() {
	amixer sget "Master" | grep -qE '\[on\]' && printf "Master" && return
	amixer sget "$EARPIECE" | grep -qE '\[on\]' && printf "%s" "$EARPIECE" && return
	amixer sget "$HEADPHONE" | grep -qE '\[on\]' && printf "%s" "$HEADPHONE" && return
	amixer sget "$SPEAKER" | grep -qE '\[on\]' && printf "%s" "$SPEAKER" && return
}

current_device() {
	if ! [ -f "$XDG_RUNTIME_DIR"/sxmo.audiocurrentdevice ]; then
		detect_device > "$XDG_RUNTIME_DIR"/sxmo.audiocurrentdevice
	fi

	cat "$XDG_RUNTIME_DIR"/sxmo.audiocurrentdevice
}

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
	sxmo_hooks.sh statusbar volume &
}

up() {
	amixer set "$(current_device)" 1%+
	notify
}
down() {
	amixer set "$(current_device)" 1%-
	notify
}
setvol() {
	amixer set "$(current_device)" "$1"%
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
