#!/bin/sh

# This script toggles the modem monitor
# It optionally takes a parameter "on" or "off"
# forcing it to toggle only to that desired state if applicable.
# It may also take a "reset" parameter that forces the
# entire modem subsystem to reload

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

daemon_start() {
	notify-send "Starting modem daemons. This may take a minute..."
	case "$OS" in
		alpine|postmarketos)
			doas rc-service "$1" start
			;;
		arch|archarm)
			[ "$1" = "modemmanager" ] && set -- ModemManager
			doas systemctl start "$1"
			;;
	esac
}

daemon_stop() {
	notify-send "Stopping modem daemons. This may take a minute..."
	case "$OS" in
		alpine|postmarketos)
			doas rc-service "$1" stop
			;;
		arch|archarm)
			[ "$1" = "modemmanager" ] && set -- ModemManager
			doas systemctl stop "$1"
			;;
	esac
}

daemon_isrunning() {
	daemon_exists "$1" || return 0
	case "$OS" in
		alpine|postmarketos)
			rc-service "$1" status | grep -q started
			;;
		arch|archarm)
			[ "$1" = "modemmanager" ] && set -- ModemManager
			systemctl is-active --quiet "$1"
			;;
	esac
}

daemon_exists() {
	case "$OS" in
		alpine|postmarketos)
			[ -f /etc/init.d/"$1" ]
			;;
		arch|archarm)
			[ "$1" = "modemmanager" ] && set -- ModemManager
			systemctl status "$1" > /dev/null 2>&1
			[ $? -ne 4 ]
			;;
	esac
}

ensure_daemon() {
	for _ in $(seq 1 10); do
		daemon_isrunning "$1" && return 0
		daemon_start "$1"
		sleep 5
	done

	return 1
}

ensure_daemons() {
	if (daemon_isrunning eg25-manager) && \
			(daemon_isrunning modemmanager); then
		return
	fi

	echo "sxmo_modemmonitortoggle: forcing modem restart" >&2
	notify-send "Resetting modem daemons, this may take a minute..."

	restart_daemons || return 1
}

restart_daemons() {
	daemon_stop modemmanager
	daemon_stop eg25-manager
	sleep 2

	if ! (ensure_daemon eg25-manager && ensure_daemon modemmanager); then
		printf "failed\n" > "$MODEMSTATEFILE"
		notify-send --urgency=critical "We failed to start the modem daemons. We may need hard reboot."
		return 1
	fi

	return 0
}

on() {
	rm "$NOTIFDIR"/incomingcall* 2>/dev/null

	TRIES=0
	while ! printf %s "$(mmcli -L)" 2> /dev/null | grep -qoE 'Modem\/([0-9]+)'; do
		TRIES=$((TRIES+1))
		if [ "$TRIES" -eq 10 ]; then
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
	ensure) ensure_daemons;;
	restart_daemons) off; restart_daemons && on;;
	start_daemons) off; restart_daemons && on;;
	stop_daemons) off; daemon_stop modemmanager; daemon_stop eg25-manager;;
	daemons_status) 
		if (daemon_isrunning eg25-manager) && \
			(daemon_isrunning modemmanager); then
			exit 0
		else
			exit 1
		fi
		;;
esac

sleep 1
sxmo_hooks.sh statusbar modem_monitor
