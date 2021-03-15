#!/usr/bin/env sh

sxmo_keyboard.sh open
OUTPUT="$(cat | dmenu "$@")"
sxmo_keyboard.sh close
echo "$OUTPUT"
