#!/usr/bin/env sh

pidof svkbd-sxmo >&2 || svkbd-sxmo &
# shellcheck disable=SC2068
OUTPUT="$(cat | dmenu $@)"
pkill svkbd-sxmo >&2
echo "$OUTPUT"
