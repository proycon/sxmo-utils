#!/bin/sh

forceupdate() {
	[ -z "$SLEEPID" ] || kill "$SLEEPID"
}
# trap USR1 as early as possible in case something sends the signal early on
# startup
trap "forceupdate" USR1

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

POLL_TIME="${SXMO_STATUSBAR_POLL_TIME:-10}"

setbar() {
	case "$SXMO_WM" in
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
	sleep "$POLL_TIME" &
	SLEEPID=$!

	update &
	UPDATEID=$!

	wait "$SLEEPID"
	unset SLEEPID
	wait "$UPDATEID"
done
