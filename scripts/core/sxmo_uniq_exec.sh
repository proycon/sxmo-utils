#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

mkdir -p "$XDG_RUNTIME_DIR/sxmo.flock"
LOCKER="$XDG_RUNTIME_DIR/sxmo.flock/$(realpath "$1" | sed 's|/|-|g').lock"

exec flock "$LOCKER" env "$@"
