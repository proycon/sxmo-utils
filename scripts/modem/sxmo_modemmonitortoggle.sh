#!/usr/bin/env sh

# This script toggles the modem monitor
# It optionally takes a parameter "on" or "off"
# forcing it to toggle only to that desired state if applicable.

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

if [ "$1" != "on" ] && pgrep -f sxmo_modemmonitor.sh; then
	pkill -TERM -f sxmo_modemmonitor.sh
elif [ "$1" != "off" ] && ! pgrep -f sxmo_modemmonitor.sh; then
	setsid -f sxmo_modemmonitor.sh &
fi

rm "$NOTIFDIR"/incomingcall*

# E.g. wait until process killed or started -- maybe there's a better way..
sleep 1

sxmo_statusbarupdate.sh
