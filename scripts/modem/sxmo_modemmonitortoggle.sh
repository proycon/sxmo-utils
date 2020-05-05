#!/usr/bin/env sh
pgrep -f sxmo_modemmonitor.sh && pkill -9 -f sxmo_modemmonitor.sh || sxmo_modemmonitor.sh &
rm /tmp/sxmo_incomingcall

# E.g. wait until process killed or started -- maybe there's a better way..
sleep 0.2

echo 1 > /tmp/sxmo_bar
