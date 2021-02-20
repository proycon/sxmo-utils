#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

DIR="$1"
[ -z "$DIR" ] && DIR="/home/$USER/"
cd "$DIR" || exit 1

while true; do
	CHOICES="$(printf %b 'Close Menu\n../\n*\n'"$(ls -1p)")"
	DIR="$(basename "$(pwd)")"
	TRUNCATED="$(printf %.7s "$DIR")"
	if [ "$DIR" != "$TRUNCATED" ]; then
		DIR="$TRUNCATED..."
	fi


	PICKED="$(
		echo "$CHOICES" |
		dmenu -c -p "$DIR" -l 20 -i
	)"

	echo "$PICKED" | grep "Close Menu" && exit 0
	[ -d "$PICKED" ] && cd "$PICKED" && continue
	echo "$PICKED" | grep -E '^[*]$' && sxmo_open.sh -a ./*
	[ -f "$PICKED" ] && sxmo_open.sh -a "$PICKED"
done
