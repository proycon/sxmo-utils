#!/usr/bin/env sh

pidof "$KEYBOARD" >&2 || "$KEYBOARD" &
OUTPUT="$(cat | dmenu "$@")"
pkill "$KEYBOARD" >&2
echo "$OUTPUT"
