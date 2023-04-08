#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

timeout="$1"
shift

finish() {
	[ -n "$CMDPID" ] && kill "$CMDPID"
	[ -n "$SLEEPPID" ] && kill "$SLEEPPID"
	exit 0
}

trap 'finish' TERM INT

while : ; do
	"$@" &
	CMDPID="$!"
	wait "$CMDPID"
	unset CMDPID

	sleep "$timeout" &
	SLEEPPID="$!"
	wait "$SLEEPPID"
	unset SLEEPPID
done
