#!/usr/bin/env sh

# This script toggles the modem monitor
# It optionally takes a parameter "on" or "off"
# forcing it to toggle only to that desired state if applicable.
# It may also take a "reset" parameter that forces the
# entire modem subsystem to reload

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

if [ "$1" = "reset" ]; then
	#does a hard reset of the entire modem
	echo "sxmo_modemmonitortoggle: forcing modem reset">&2
	notify-send "Resetting modem, this may take a minute..."
	pkill -TERM -f sxmo_modemmonitor.sh
	sudo rc-service modemmanager stop
	sudo rc-service eg25-manager stop
	sleep 5
	while ! rc-service eg25-manager status | grep -q started; do
		sudo rc-service eg25-manager start
		sleep 2
	done
	sleep 5
	sudo rc-service modemmanager start
	sleep 30
	setsid -f sxmo_modemmonitor.sh &
elif [ "$1" != "on" ] && pgrep -f sxmo_modemmonitor.sh; then
	pkill -TERM -f sxmo_modemmonitor.sh
elif [ "$1" != "off" ] && ! pgrep -f sxmo_modemmonitor.sh; then
	setsid -f sxmo_modemmonitor.sh &
fi

rm "$NOTIFDIR"/incomingcall*

# E.g. wait until process killed or started -- maybe there's a better way..
sleep 1

sxmo_statusbarupdate.sh
