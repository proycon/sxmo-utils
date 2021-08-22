#!/bin/sh

if [ "$1" = clear ]; then
	rm -f "$XDG_RUNTIME_DIR"/sxmo.multikey.count.*
	exit
fi

identifier="$1"
threshold="${SXMO_THRESHOLD:-0.30}"

count_file="$XDG_RUNTIME_DIR"/sxmo.multikey.count."$identifier"

if [ -f "$count_file" ]; then
	counter="$(($(cat "$count_file")+1))"
else
	counter=1
fi

shift "$counter"
if [ "$#" -eq 0 ]; then
	exit
fi
printf %s "$counter" > "$count_file"

sleep "$threshold"

if [ "$counter" != "$(cat "$count_file")" ]; then
	exit
fi

eval "$1" &

if [ "$#" -eq 1 ]; then
	sleep "$threshold" # prevent holded presses to chain
fi

rm "$count_file"

