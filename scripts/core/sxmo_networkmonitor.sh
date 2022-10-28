#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

gracefulexit() {
	sxmo_log "gracefully exiting (on signal or after error)"
	sxmo_daemons.sh stop network_monitor_device
	trap - INT TERM EXIT
}

trap "gracefulexit" INT TERM EXIT

getdevtype() {
	nmcli -g GENERAL.TYPE device show "$1" 2>/dev/null
}

# Send the initial states to the statusbar
nmcli -g GENERAL.TYPE,GENERAL.DEVICE d show | grep . | while read -r type; do
	read -r name || break
	sxmo_log "$name initializing network tracking"
	sxmo_hook_statusbar.sh network "$type" "$name"
done

# shellcheck disable=2016
sxmo_daemons.sh start network_monitor_device \
	nmcli device monitor | stdbuf -o0 awk '
	{ newstate=$2 }
	/device removed$/ {newstate="disconnected"}
	newstate == "unavailable" {newstate="disconnected"}

	{
		sub(":$", "", $1) # remove trailing colon from device name
		printf "%s\n%s\n", $1, newstate
	}' | while read -r devicename; do
		read -r newstate || break

		devicetype="$(getdevtype "$devicename")"
		case "$newstate" in
			"connected")
				sxmo_log "$devicename up"
				sxmo_hook_network_up.sh "$devicename" "$devicetype"
				sxmo_hook_statusbar.sh network "$devicetype" "$devicename"
				;;
			"disconnected")
				sxmo_log "$devicename down"
				sxmo_hook_network_down.sh "$devicename" "$devicetype"
				sxmo_hook_statusbar.sh network "$devicetype" "$devicename"
				;;
			"deactivating")
				sxmo_log "$devicename pre-down"
				sxmo_hook_network_pre_down.sh "$devicename" "$devicetype"
				sxmo_hook_statusbar.sh network "$devicetype" "$devicename"
				;;
			"connecting")
				sxmo_log "$devicename pre-up"
				sxmo_hook_network_pre_up.sh "$devicename" "$devicetype"
				sxmo_hook_statusbar.sh network "$devicetype" "$devicename"
				;;
			*)
				sxmo_log "$devicename unknown state $newstate"
				;;
		esac
	done
