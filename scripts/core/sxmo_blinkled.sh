#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

PIDS=""
for i in "$@"; do
	sxmo_setpineled "$i" 150 &
	PIDS="$PIDS $!"
done

echo "$PIDS" | grep -E '[^ ]+' | xargs wait

for i in "$@"; do
	sxmo_setpineled "$i" 0
done
