#!/usr/bin/env sh
PIDS=""
for i in "$@"; do
	sxmo_setpineled "$i" 150 &
	PIDS="$PIDS $!"
done

echo "$PIDS" | grep -E '[^ ]+' | xargs wait

for i in "$@"; do
	sxmo_setpineled "$i" 0
done
