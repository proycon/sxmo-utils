#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

WM="$SXMO_WM"

forceupdate() {
	kill "$SLEEPID"
}
trap "forceupdate" USR1

setbar() {
	case "$WM" in
		dwm) xsetroot -name "$*";;
		*) printf "%s\n" "$*";;
	esac
}

update() {
	BAR="$(sxmo_hooks.sh statusbar)"
	[ -z "$SLEEPID" ] && return # to prevent mid rendering interuption
	setbar "$BAR"
}

setbar "SXMO : Simple Mobile"

while :
do
	sleep 10 &
	SLEEPID=$!

	update &
	UPDATEID=$!

	wait "$SLEEPID"
	unset SLEEPID
	wait "$UPDATEID"
done
