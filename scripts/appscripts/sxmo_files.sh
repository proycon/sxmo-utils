#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

DIR="$1"
[ -z "$DIR" ] && DIR="/home/$USER/"
cd "$DIR" || exit 1

SORT=
REVERSE=

sort_loop() {
	CHOICES="$([ -z "$SORT" ] && echo "date" || echo "name")\n$([ -z "$REVERSE" ] && echo "desc" || echo "asc")"

	PICKED="$(
		printf %b "$CHOICES" |
		dmenu -c -p "Sort" -l 10 -i
	)"

	echo "$PICKED" | grep -q "date" && SORT="--sort=t"
	echo "$PICKED" | grep -q "name" && SORT=
	echo "$PICKED" | grep -q "desc" && REVERSE="-r"
	echo "$PICKED" | grep -q "asc" && REVERSE=
}


while true; do
	CHOICES="$(printf %b 'Reload\nClose Menu\nSort By\n../\n*\n'"$(ls -1p $SORT $REVERSE)")"
	DIR="$(basename "$(pwd)")"
	TRUNCATED="$(printf %.7s "$DIR")"
	if [ "$DIR" != "$TRUNCATED" ]; then
		DIR="$TRUNCATED..."
	fi


	PICKED="$(
		echo "$CHOICES" |
		dmenu -c -p "$DIR" -l 20 -i
	)"

	echo "$PICKED" | grep "Sort By" && sort_loop
	echo "$PICKED" | grep "Close Menu" && exit 0
	echo "$PICKED" | grep "Reload" && continue
	[ -d "$PICKED" ] && cd "$PICKED" && continue
	echo "$PICKED" | grep -E '^[*]$' && sxmo_open.sh -a ./*
	[ -f "$PICKED" ] && sxmo_open.sh -a "$PICKED"
done
