#!/usr/bin/env sh

sxmo_keyboard.sh on &
OUTPUT="$(cat | dmenu -t $@)"
sxmo_keyboard.sh off
echo "$OUTPUT"
