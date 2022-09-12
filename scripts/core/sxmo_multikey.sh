#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

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

printf %s "$counter" > "$count_file"

shift "$counter"
if [ "$#" -eq 0 ]; then
	exit
fi

sleep "$threshold"

new_counter="$(cat "$count_file")"
if [ "$counter" != "$new_counter" ] && [ "$#" -ne 1 ]; then # Only the last count can overflow
	exit
fi

eval sxmo_hook_inputhandler.sh "$1" &

if [ "$counter" != "$new_counter" ]; then # overlowed
	printf "%s * 2" "$threshold" | bc | xargs sleep
fi

rm "$count_file"

