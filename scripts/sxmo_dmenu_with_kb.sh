#!/usr/bin/env sh

pidof svkbd-sxmo || svkbd-sxmo &
OUTPUT="$(cat | dmenu -t $@)"
pkill svkbd-sxmo 
echo "$OUTPUT"
