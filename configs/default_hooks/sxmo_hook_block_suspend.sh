#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This hook checks for tasks that should block suspend, but don't report it to
# the wakelock system we use. When it exits it means the system can suspend.
#
# A check consists of two components:
#  - How to check if it is active (blocking suspend)
#  - Optionally, how to wait for the next check. Currently the only implemented
#    method is exponential backoff (called delay) which is the default if none
#    is provided.
#
# NOTE: If you're trying to extend this hook, skip to the while loop at the bottom

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

# Basic exponential backoff, this should save some resources if we're blocked by
# the same thing for a while
delay() {
	sleep "$delay_time"
	delay_time="$((delay_time*2))"
	if [ "$delay_time" -gt 45 ]; then
		delay_time=45
	fi
}

wait_item() {
	delay_time=1
	while $1 > /dev/null 2>&1; do
		sxmo_log "Blocking suspend for $1"
		waited=1
		${2:-delay}
	done
}

#
# helper functions for checking blockers
#

suspend_disabled() {
	test -e "$XDG_CACHE_HOME/sxmo/sxmo.nosuspend"
}

in_call() {
	pgrep -f sxmo_modemcall.sh
}

in_call_dino() {
	command -v pw-link && [ -n "$(pw-link -o Dino)" ]
}

hotspot_active() {
	nmcli -t c show --active | grep -q ^Hotspot
}

ssh_connected() {
	netstat -tn | awk '
		BEGIN { status = 1 }
		$4 ~ /:22$/ { status = 0; exit }
		END { exit status }
		'
}

active_mosh() {
	command -v mosh-server && pgrep -f mosh-server
}

playing_mpc() {
	command -v mpc && mpc status | grep -q '\[playing\]'
}

playing_mpris() {
	command -v playerctl && playerctl -a status | grep -q "Playing"
}

photos_processing() {
	pgrep -f postprocess
}

#
# Wait for all blockers
#
while [ "$waited" != "0" ]; do
	waited=0
	wait_item suspend_disabled
	wait_item in_call
	wait_item in_call_dino
	wait_item hotspot_active
	wait_item ssh_connected
	wait_item active_mosh
	wait_item playing_mpc
	wait_item playing_mpris
	wait_item photos_processing
done
