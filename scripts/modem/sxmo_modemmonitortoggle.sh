#!/usr/bin/env sh

# This script toggles the modem monitor
# It optionally takes a parameter "on" or "off"
# forcing it to toggle only to that desired state if applicable.
# It may also take a "reset" parameter that forces the
# entire modem subsystem to reload

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

ensure_daemon() {
	TRIES=0
	while ! rc-service "$1" status | grep -q started; do
		if [ "$TRIES" -eq 10 ]; then
			return 1
		fi
		TRIES=$((TRIES+1))
		sudo rc-service "$1" start
		sleep 5
	done

	return 0
}

ensure_daemons() {
	if (rc-service eg25-manager status | grep -q started) &&
		(rc-service modemmanager status | grep -q started); then
		return
	fi

	echo "sxmo_modemmonitortoggle: forcing modem restart" >&2
	notify-send "Resetting modem daemons, this may take a minute..."

	sudo rc-service modemmanager stop
	sudo rc-service eg25-manager stop
	sleep 2

	if ! (ensure_daemon eg25-manager && ensure_daemon modemmanager); then
		printf "failed\n" > "$MODEMSTATEFILE"
		notify-send --urgency=critical "We failed to start the modem daemons. We may need hard reboot."
		return 1
	fi
}

on() {
	rm "$NOTIFDIR"/incomingcall*

	TRIES=0
	while ! printf %s "$(mmcli -L)" 2> /dev/null | grep -qoE 'Modem\/([0-9]+)'; do
		TRIES=$((TRIES+1))
		if [ "$TRIES" -eq 10 ]; then
			printf "failed\n" > "$MODEMSTATEFILE"
			notify-send --urgency=critical "We failed to start the modem monitor. We may need hard reboot."
		fi
		sleep 5
	done

	setsid -f sxmo_modemmonitor.sh &

	sleep 1
}

off() {
	pkill -TERM -f sxmo_modemmonitor.sh
}

if [ -z "$1" ]; then
	if pgrep -f sxmo_modemmonitor.sh; then
		set -- off
	else
		set -- on
	fi
fi

case "$1" in
	restart) off; ensure_daemons && on;;
	on) ensure_daemons && on;;
	off) off;;
esac

sxmo_statusbarupdate.sh
