#!/bin/sh

mkdir -p "$XDG_RUNTIME_DIR/sxmo.flock"
LOCKER="$XDG_RUNTIME_DIR/sxmo.flock/$(realpath "$1" | sed 's|/|-|g').lock"

exec flock "$LOCKER" env "$@"
