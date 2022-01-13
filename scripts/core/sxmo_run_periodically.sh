#!/bin/sh

timeout="$1"
shift

while : ; do
	"$@"
	sleep "$timeout" &
	wait
done
