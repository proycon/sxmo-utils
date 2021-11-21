#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

stderr() {
	printf "sxmo_networkmonitor %s: %s\n" "$(date)" "$*" >&2
}

gracefulexit() {
	sxmo_statusbarupdate.sh
	sleep 1
	stderr "gracefully exiting (on signal or after error)"
	kill -9 0
}

trap "gracefulexit" INT TERM

dbus-monitor --system "interface='org.freedesktop.NetworkManager',type='signal',member='StateChanged'" | \
	while read -r line; do
		if echo "$line" | grep -E "^signal.*StateChanged"; then
			# shellcheck disable=SC2034
			read -r newstate
			if echo "$newstate" | grep "int32 70"; then
				#network just connected (70=NM_STATE_CONNECTED_GLOBAL)
				stderr "network up."
				sxmo_hooks.sh network-up &
				sxmo_statusbarupdate.sh
			elif echo "$newstate" | grep "int32 20"; then
				#network just disconnected (20=NM_STATE_DISCONNECTED)
				stderr "network down."
				sxmo_hooks.sh network-down &
				sxmo_statusbarupdate.sh
			elif echo "$newstate" | grep "int32 30"; then
				#network is going down (30=NM_STATE_DISCONNECTING)
				sxmo_hooks.sh network-pre-down &
			fi
		fi
	done &

wait
