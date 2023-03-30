#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

if [ "$1" = "-" ]; then
	waitfirst=1
	shift
fi

timeout="$1"
shift

finish() {
	kill "$CMDPID"
	kill "$SLEEPPID"
	exit 0
}

trap 'finish' TERM INT

if [ -n "$waitfirst" ]; then
	sleep "$timeout" &
	SLEEPPID="$!"
	wait "$SLEEPPID"
fi

while : ; do
	"$@" &
	CMDPID="$!"
	wait "$CMDPID"

	sleep "$timeout" &
	SLEEPPID="$!"
	wait "$SLEEPPID"
done
