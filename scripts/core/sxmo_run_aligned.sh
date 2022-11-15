#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

timeout="$1"
shift

finish() {
	kill "$CMDPID"
	kill "$SLEEPPID"
	exit 0
}

trap 'finish' TERM INT

while : ; do
	"$@" &
	CMDPID="$!"
	wait "$CMDPID"

	sxmo_aligned_sleep "$timeout" &
	SLEEPPID="$!"
	wait "$SLEEPPID"
done
