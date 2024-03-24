#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

usage() {
	cat <<-EOF >&2
		Usage: $(basename "$0") [-w] <timeout> [--] <cmd...>
	EOF
	exit 1
}

while [ -n "$*" ]; do
	case "$1" in
		"--")
			shift
			break;
			;;
		"-w")
			waitfirst=1
			shift
			;;
		*)
			if [ -n "$timeout" ]; then
				break;
			fi
			timeout="$1"
			shift
			;;
	esac
done

if [ -z "$timeout" ] || [ -z "$*" ]; then
	usage
fi

finish() {
	[ -n "$CMDPID" ] && kill "$CMDPID"
	[ -n "$SLEEPPID" ] && kill "$SLEEPPID"
	exit 0
}

trap 'finish' TERM INT

if [ -n "$waitfirst" ]; then
	sleep "$timeout" &
	SLEEPPID="$!"
	wait "$SLEEPPID"
	unset SLEEPPID
fi

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
