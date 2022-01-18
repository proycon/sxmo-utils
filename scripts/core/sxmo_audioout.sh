#!/bin/sh
ARG="$1"

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

SPEAKER="${SPEAKER:-"Line Out"}"
HEADPHONE="${HEADPHONE:-"Headphone"}"
EARPIECE="${EARPIECE:-"Earpiece"}"

amixer set "Master" mute
amixer set "$SPEAKER" mute
amixer set "$HEADPHONE" mute
amixer set "$EARPIECE" mute

if [ "$ARG" = "Master" ]; then
	amixer set "Master" unmute
elif [ "$ARG" = "Speaker" ]; then
	amixer set "$SPEAKER" unmute
elif [ "$ARG" = "Headphones" ]; then
	amixer set "$HEADPHONE" unmute
elif [ "$ARG" = "Earpiece" ]; then
	amixer set "$EARPIECE" unmute
fi

sxmo_hooks.sh statusbar volume
