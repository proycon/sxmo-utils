#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

stderr() {
	sxmo_log "$*"
}

gracefulexit() {
	sxmo_hooks.sh statusbar wifi
	stderr "gracefully exiting (on signal or after error)"
	sxmo_daemons.sh stop network_monitor_device
	exit
}

trap "gracefulexit" INT TERM EXIT

_getdevicename() {
	dbus-send --system --print-reply --dest=org.freedesktop.NetworkManager \
		/org/freedesktop/NetworkManager/Devices/"$1" \
		org.freedesktop.DBus.Properties.Get \
		string:"org.freedesktop.NetworkManager.Device" \
		string:"Interface" | grep variant | cut -d'"' -f2
}

# see https://people.freedesktop.org/~lkundrak/nm-docs/nm-dbus-types.html
# from my tests, when you disconnect wifi network it goes: 100 -> 110 -> 30
# when you connect wifi network: 30 -> 40 -> 50 -> 60 -> 40 -> 50 -> 70 -> 80 -> 90 -> 100
sxmo_daemons.sh start network_monitor_device \
	dbus-monitor --system "interface='org.freedesktop.NetworkManager.Device',type='signal',member='StateChanged'" | \
	while read -r line; do
		if echo "$line" | grep -qE "^signal.*StateChanged"; then
			device="$(printf "%s\n" "$line" | cut -d'/' -f 6 | cut -d';' -f1)"
			read -r newstate
			read -r oldstate
			read -r reason
			sxmo_debug "$device ($oldstate -> $newstate) [$reason]"

			devicename="$(_getdevicename "$device")"
			if echo "$newstate" | grep -q "uint32 100"; then
				# 100=NM_DEVICE_STATE_ACTIVATED
				stderr "$devicename up."
				sxmo_hooks.sh network-up "$devicename"
				sxmo_hooks.sh statusbar "network_$devicename"
			elif echo "$newstate" | grep -q "uint32 30"; then
				# 30=NM_DEVICE_STATE_DISCONNECTED 
				stderr "$devicename down."
				sxmo_hooks.sh network-down "$devicename"
				sxmo_hooks.sh statusbar "network_$devicename"
			elif echo "$newstate" | grep -q "uint32 110"; then
				# 110=NM_DEVICE_STATE_DEACTIVATING
				stderr "$devicename pre-down"
				sxmo_hooks.sh network-pre-down "$devicename"
				sxmo_hooks.sh statusbar "network_$devicename"
			elif echo "$newstate" | grep -q "uint32 90"; then
				# 90=NM_DEVICE_STATE_SECONDARIES
				stderr "$devicename pre-up"
				sxmo_hooks.sh network-pre-up "$devicename"
				sxmo_hooks.sh statusbar "network_$devicename"
			fi
		fi
	done
