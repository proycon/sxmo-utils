#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

PIDS=""
for i in "$@"; do
	sxmo_setled.sh "$i" 150 &
	PIDS="$PIDS $!"
done

echo "$PIDS" | grep -E '[^ ]+' | xargs wait

# Make blink noticable
sleep 0.1

for i in "$@"; do
	sxmo_setled.sh "$i" 0
done
