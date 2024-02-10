#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script is responsible for starting wob, or xob, and making sure it exits cleanly

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

ob_sock="$XDG_RUNTIME_DIR"/sxmo.obsock
rm -f "$ob_sock"
mkfifo "$ob_sock"

# By opening the socket as read-write it isn't closed after the first write
# see https://unix.stackexchange.com/questions/392697
"${1:-wob}" <> "$ob_sock" &
OBPID=$!

finish() {
	# Only finish once
	trap - TERM INT EXIT
	kill "$OBPID"
	rm -f "$ob_sock"
}
trap 'finish' TERM INT EXIT

wait "$OBPID"
