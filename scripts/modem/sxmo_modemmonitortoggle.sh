#!/usr/bin/env sh
if pgrep -f sxmo_modemmonitor.sh; then
	pkill -9 -f sxmo_modemmonitor.sh
else
	sxmo_modemmonitor.sh &
fi

rm /tmp/sxmo_incomingcall

# E.g. wait until process killed or started -- maybe there's a better way..
sleep 1

echo 1 > /tmp/sxmo_bar
