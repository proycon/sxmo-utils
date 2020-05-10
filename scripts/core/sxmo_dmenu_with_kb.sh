#!/usr/bin/env sh

pidof svkbd-sxmo >&2 || svkbd-sxmo &
OUTPUT="$(cat | dmenu $@)"
pkill svkbd-sxmo >&2
echo "$OUTPUT"
