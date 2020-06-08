#!/usr/bin/env sh
EDITOR=vis
cd "/home/$USER/" || exit 1

handlefiles() {
	if echo "$1" | grep -iE ".(wav|webm|mp4|ogg|opus|m4a|flac|mov|avi)$"; then
		st -e mpv "$@"
	elif echo "$1" | grep -iE ".(jpg|png|gif)$"; then
		st -e sxiv "$@"
	else
		st -e sh -ic "$EDITOR $*"
	fi
	exit 0
}

while true; do
	CHOICES="$(printf %b 'Close Menu\n../\n*\n'"$(ls -1p)")"
	DIR="$(basename "$(pwd)")"
	PICKED="$(
		echo "$CHOICES" |
		dmenu -fn Terminus-18 -c -p "$DIR" -l 20
	)"

	echo "$PICKED" | grep "Close Menu" && exit 0
	[ -d "$PICKED" ] && cd "$PICKED" && continue
	echo "$PICKED" | grep -E '^[*]$' && handlefiles ./*
	[ -f "$PICKED" ] && handlefiles "$PICKED"
done
