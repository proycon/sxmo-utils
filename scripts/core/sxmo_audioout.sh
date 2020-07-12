#!/usr/bin/env sh
ARG="$1"

SPEAKER="Line Out"
HEADPHONE="Headphone"
EARPIECE="Earpiece"

amixer set "$SPEAKER" mute
amixer set "$HEADPHONE" mute
amixer set "$EARPIECE" mute

if [ "$ARG" = "Speaker" ]; then
	amixer set "$SPEAKER" unmute
elif [ "$ARG" = "Headphones" ]; then
	amixer set "$HEADPHONE" unmute
elif [ "$ARG" = "Earpiece" ]; then
	amixer set "$EARPIECE" unmute
fi

pgrep -f "$(command -v sxmo_statusbar.sh)" | xargs kill -USR1
