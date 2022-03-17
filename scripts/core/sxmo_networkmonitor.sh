#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

stderr() {
	sxmo_log "$*"
}

gracefulexit() {
	sxmo_hook_statusbar.sh wifi
	stderr "gracefully exiting (on signal or after error)"
	sxmo_daemons.sh stop network_monitor_device
	trap - INT TERM EXIT
}

trap "gracefulexit" INT TERM EXIT

# shellcheck disable=2016
sxmo_daemons.sh start network_monitor_device \
	nmcli device monitor | stdbuf -o0 awk '
	{ newstate=$2 }
	/device removed$/ {newstate="disconnected"}

	{
		sub(":$", "", $1) # remove trailing colon from device name
		printf "%s\n%s\n", $1, newstate
	}' | while read -r devicename; do
		read -r newstate || break

		case "$newstate" in
			"connected")
				stderr "$devicename up."
				sxmo_hook_network_up.sh "$devicename"
				sxmo_hook_statusbar.sh "network_$devicename"
				;;
			"disconnected")
				stderr "$devicename down."
				sxmo_hook_network_down.sh "$devicename"
				sxmo_hook_statusbar.sh "network_$devicename"
				;;
			"deactivating")
				stderr "$devicename pre-down"
				sxmo_hook_network_pre_down.sh "$devicename"
				sxmo_hook_statusbar.sh "network_$devicename"
				;;
			"connecting")
				stderr "$devicename pre-up"
				sxmo_hook_network_pre_up.sh "$devicename"
				sxmo_hook_statusbar.sh "network_$devicename"
				;;
		esac
	done
