#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

wtype_to_xdotool() {
	if [ "$#" -eq 0 ]; then
		exit
	fi

	if [ "-M" = "$1" ] || [ "-P" = "$1" ]; then
		key="$2"
		shift 2
		xdotool keydown "$key"
		sxmo_type.sh "$@"
		xdotool keyup "$key"
		exit
	elif [ "-m" = "$1" ] || [ "-p" = "$1" ]; then
		xdotool keyup "$2"
		shift 2
	elif [ "-k" = "$1" ]; then
		xdotool key "$2"
		shift 2
	elif [ "-s" = "$1" ]; then
		printf 'scale=2; %s/1000\n' "$2" | bc -l | xargs xdotool sleep
		shift 2
	else
		xdotool type "$1"
		shift
	fi

	wtype_to_xdotool "$@"
}

case "$SXMO_WM" in
	sway)
		wtype "$@"
		;;
	dwm)
		wtype_to_xdotool "$@"
		;;
esac
