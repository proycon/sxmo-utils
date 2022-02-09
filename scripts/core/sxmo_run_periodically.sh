#!/bin/sh

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

	sleep "$timeout" &
	SLEEPPID="$!"
	wait "$SLEEPPID"
done
