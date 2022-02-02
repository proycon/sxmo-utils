#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

set -e

usage() {
	printf "%s <FILES> [--date-sort] [--reverse-sort] [--select-only] [-h help]\n" \
		"$(basename "$0")"
	exit 1
}

DIR="$HOME"
SORT=
REVERSE=
SELECTONLY=0

while [ -n "$1" ]; do
	case "$1" in
		--select-only)
			SELECTONLY=1
			;;
		--date-sort)
			SORT="--sort=t"
			;;
		--reverse-sort)
			REVERSE="-r"
			;;
		-h)
			usage
			;;
		*)
			DIR="$1"
	esac
	shift
done

cd "$DIR"

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
			if [ -n "$SELECTONLY" ]; then
				printf %s "Can't do this"
			else
				sxmo_open.sh -a ./*
			fi
			;;
		*)
			[ -d "$PICKED" ] && cd "$PICKED" && continue
			if [ -f "$PICKED" ]; then
				if [ "$SELECTONLY" -eq 1 ]; then
					printf "%s" "$(pwd)/$PICKED" && exit
				else
					sxmo_open.sh -a "$PICKED"
				fi
			fi
			;;
	esac
done
