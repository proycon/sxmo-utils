#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

WM="$(sxmo_wm.sh)"

forceupdate() {
	kill "$SLEEPID"
}
trap "forceupdate" USR1

setbar() {
	case "$WM" in
		sway|ssh) printf "%s\n" "$*";;
		dwm) xsetroot -name "$*";;
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
