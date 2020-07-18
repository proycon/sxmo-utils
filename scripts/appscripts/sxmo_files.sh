#!/usr/bin/env sh
DIR="$1"
[ -z "$DIR" ] && DIR="/home/$USER/"
cd "$DIR" || exit 1

handlefiles() {
	if echo "$1" | grep -iE ".(webm|ogg|mp4|mov|avi)$"; then
		st -e mpv -ao=alsa "$@"
	elif echo "$1" | grep -iE ".(wav|opus|m4a|flac|mp3)$"; then
		st -e mpv -ao=alsa --vid=no -v "$@"
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
	TRUNCATED="$(printf %.7s "$DIR")"
	if [ "$DIR" != "$TRUNCATED" ]; then
		DIR="$TRUNCATED..."
	fi


	PICKED="$(
		echo "$CHOICES" |
		dmenu -fn Terminus-18 -c -p "$DIR" -l 20 -i
	)"

	echo "$PICKED" | grep "Close Menu" && exit 0
	[ -d "$PICKED" ] && cd "$PICKED" && continue
	echo "$PICKED" | grep -E '^[*]$' && handlefiles ./*
	[ -f "$PICKED" ] && handlefiles "$PICKED"
done
