#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

stderr() {
	printf "%s sxmo_networkmonitor: %s\n" "$(date)" "$*" >&2
}

gracefulexit() {
	sxmo_statusbarupdate.sh
	sleep 1
	stderr "gracefully exiting (on signal or after error)"
	kill -9 0
}

trap "gracefulexit" INT TERM

# see https://people.freedesktop.org/~lkundrak/nm-docs/nm-dbus-types.html
# from my tests, when you disconnect wifi network it goes: 100 -> 110 -> 30
# when you connect wifi network: 30 -> 40 -> 50 -> 60 -> 40 -> 50 -> 70 -> 80 -> 90 -> 100
dbus-monitor --system "interface='org.freedesktop.NetworkManager.Device',type='signal',member='StateChanged'" | \
	while read -r line; do
		if echo "$line" | grep -qE "^signal.*StateChanged"; then
			# shellcheck disable=SC2034
			read -r newstate
			# shellcheck disable=SC2034
			read -r oldstate
			# shellcheck disable=SC2034
			read -r reason
			stderr "oldstate: $oldstate newstate: $newstate reason: $reason"
			if echo "$newstate" | grep "uint32 100"; then
				# 100=NM_DEVICE_STATE_ACTIVATED
				stderr "network up."
				sxmo_hooks.sh network-up &
				sxmo_statusbarupdate.sh network-up
			elif echo "$newstate" | grep "uint32 30"; then
				# 30=NM_DEVICE_STATE_DISCONNECTED 
				stderr "network down."
				sxmo_hooks.sh network-down &
				sxmo_statusbarupdate.sh network-down
			elif echo "$newstate" | grep "uint32 110"; then
				# 110=NM_DEVICE_STATE_DEACTIVATING
				stderr "network pre-down"
				sxmo_hooks.sh network-pre-down &
				sxmo_statusbarupdate.sh network-pre-down
			elif echo "$newstate" | grep "uint32 90"; then
				# 90=NM_DEVICE_STATE_SECONDARIES
				stderr "network pre-up"
				sxmo_hooks.sh network-pre-up &
				sxmo_statusbarupdate.sh network-pre-up
			fi
		fi
	done &

wait
