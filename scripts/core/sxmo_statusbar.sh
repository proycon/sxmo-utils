#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

WM="$(sxmo_wm.sh)"

forceupdate() {
	kill "$SLEEPID"
}
trap "forceupdate" USR1

update() {
	BAR="$(sxmo_hooks.sh statusbar)"
	[ -z "$SLEEPID" ] && return # to prevent mid rendering interuption
	printf %s "$BAR" | case "$WM" in
		sway|ssh) xargs -0 printf "%s\n";;
		dwm) xargs -0 xsetroot -name;;
	esac
}

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
