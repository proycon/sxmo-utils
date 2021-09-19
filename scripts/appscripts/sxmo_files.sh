#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

set -e

DIR="$1"
[ -z "$DIR" ] && DIR="$HOME"
cd "$DIR" || exit 1

SORT=
REVERSE=

sort_loop() {
	CHOICES="$([ -z "$SORT" ] && printf "date" || printf "name")\n$([ -z "$REVERSE" ] && printf "desc" || printf "asc")\n"

	PICKED="$(
		printf %b "$CHOICES" |
		sxmo_dmenu.sh -p "Sort" -i
	)"

	case "$PICKED" in
		"date")
			SORT="--sort=t"
			;;
		"name")
			SORT=
			;;
		"desc")
			REVERSE="-r"
			;;
		"asc")
			REVERSE=
			;;
	esac
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
		printf %b "$CHOICES" |
		sxmo_dmenu.sh -p "$DIR" -i
	)"

	case "$PICKED" in
		"Sort By")
			sort_loop
			;;
		"Open in terminal")
			cd "$(pwd)" && sxmo_terminal.sh && continue
			;;
		"Close Menu")
			exit 0
			;;
		"Reload")
			continue
			;;
		\*)
			sxmo_open.sh -a ./*
			;;
		*)
			[ -d "$PICKED" ] && cd "$PICKED" && continue
			[ -f "$PICKED" ] && sxmo_open.sh -a "$PICKED"
			;;
	esac
done
