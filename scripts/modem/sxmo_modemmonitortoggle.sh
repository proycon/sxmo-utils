#!/usr/bin/env sh
if pgrep -f sxmo_modemmonitor.sh; then
	pgrep -f sxmo_modemmonitor.sh | grep -Ev "^${$}$" | xargs -IP kill -TERM P
else
	sxmo_modemmonitor.sh &
fi

NOTIFDIR="$XDG_CONFIG_HOME"/sxmo/notifications
rm $NOTIFDIR/incomingcall*

# E.g. wait until process killed or started -- maybe there's a better way..
sleep 1

sxmo_statusbarupdate.sh
