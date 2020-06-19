#!/usr/bin/env sh
if pgrep -f sxmo_modemmonitor.sh; then
	pgrep -f sxmo_modemmonitor.sh | grep -Ev "^${$}$" | xargs -IP kill -TERM P
else
	sxmo_modemmonitor.sh &
fi

rm /tmp/sxmo_incomingcall

# E.g. wait until process killed or started -- maybe there's a better way..
sleep 1

echo 1 > /tmp/sxmo_bar
