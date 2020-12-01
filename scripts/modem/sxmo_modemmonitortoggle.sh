#!/usr/bin/env sh

# This script toggles the modem monitor
# It optionally takes a parameter "on" or "off"
# forcing it to toggle only to that desired state if applicable.

if [ "$1" != "on" ] && pgrep -f sxmo_modemmonitor.sh; then
	pgrep -f sxmo_modemmonitor.sh | grep -Ev "^${$}$" | xargs -IP kill -TERM P
elif [ "$1" != "off" ]; then
	setsid -f sxmo_modemmonitor.sh &
fi

NOTIFDIR="$XDG_CONFIG_HOME"/sxmo/notifications
rm "$NOTIFDIR"/incomingcall*

# E.g. wait until process killed or started -- maybe there's a better way..
sleep 1

sxmo_statusbarupdate.sh
