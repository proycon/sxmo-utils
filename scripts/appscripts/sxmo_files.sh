#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

DIR="$1"
[ -z "$DIR" ] && DIR="$HOME"
cd "$DIR" || exit 1

SORT=
REVERSE=

sort_loop() {
	CHOICES="$([ -z "$SORT" ] && echo "date" || echo "name")\n$([ -z "$REVERSE" ] && echo "desc" || echo "asc")"

	PICKED="$(
		printf %b "$CHOICES" |
		sxmo_dmenu.sh -p "Sort" -i
	)"

	echo "$PICKED" | grep -q "date" && SORT="--sort=t"
	echo "$PICKED" | grep -q "name" && SORT=
	echo "$PICKED" | grep -q "desc" && REVERSE="-r"
	echo "$PICKED" | grep -q "asc" && REVERSE=
}


while true; do
	# shellcheck disable=SC2086
	FILES="$(ls -1p $SORT $REVERSE)"
	CHOICES="$(printf %b 'Reload\nOpen in terminal\nClose Menu\nSort By\n../\n*\n'"$FILES")"
	DIR="$(basename "$(pwd)")"
	TRUNCATED="$(printf %.7s "$DIR")"
	if [ "$DIR" != "$TRUNCATED" ]; then
		DIR="$TRUNCATED..."
	fi


	PICKED="$(
		echo "$CHOICES" |
		sxmo_dmenu.sh -p "$DIR" -i
	)" || exit

	echo "$PICKED" | grep "Sort By" && sort_loop
	echo "$PICKED" | grep "Open in terminal" && cd "$(pwd)" && sxmo_terminal.sh
	echo "$PICKED" | grep "Close Menu" && exit 0
	echo "$PICKED" | grep "Reload" && continue
	[ -d "$PICKED" ] && cd "$PICKED" && continue
	echo "$PICKED" | grep -E '^[*]$' && sxmo_open.sh -a ./*
	if [ -f "$PICKED" ] || [ "$PICKED" =  "Open in terminal" ]; then
		echo "$FILES" | sed -n -e "/$PICKED/,\$p" | tr '\n' '\0' | xargs -0 sxmo_open.sh -a
	fi
done
