#!/bin/sh
ARG="$1"

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

SPEAKER="${SPEAKER:-"Line Out"}"
HEADPHONE="${HEADPHONE:-"Headphone"}"
EARPIECE="${EARPIECE:-"Earpiece"}"

amixer set "Master" mute >/dev/null 2>/dev/null
amixer set "$SPEAKER" mute >/dev/null
amixer set "$HEADPHONE" mute >/dev/null
amixer set "$EARPIECE" mute >/dev/null

if [ "$ARG" = "Master" ]; then
	DEV="Master"
elif [ "$ARG" = "Speaker" ]; then
	DEV="$SPEAKER"
elif [ "$ARG" = "Headphones" ]; then
	DEV="$HEADPHONE"
elif [ "$ARG" = "Earpiece" ]; then
	DEV="$EARPIECE"
else
	# Mute/None
	DEV=""
fi
if [ "$DEV" ]; then
	amixer set "$DEV" unmute
fi
printf '%s' "$DEV" > "$XDG_RUNTIME_DIR/sxmo.audiocurrentdevice"

sxmo_hooks.sh statusbar volume
