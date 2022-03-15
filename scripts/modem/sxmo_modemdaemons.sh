#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script handles the modem-related daemons on the system, e.g., eg25-manager, modemmonitor, etc.

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

daemon_start() {
	if ! daemon_exists "$1"; then
		sxmo_notify_user.sh "$1 does not exist on the system"
		return 1
	fi
	if daemon_isrunning "$1"; then
		sxmo_notify_user.sh "$1 is already running"
		return 0
	fi
	case "$OS" in
		alpine|postmarketos)
			doas rc-service "$1" start
			;;
		arch|archarm|debian)
			[ "$1" = "modemmanager" ] && set -- ModemManager
			doas systemctl start "$1"
			;;
	esac
}

daemon_stop() {
	if ! daemon_exists "$1"; then
		sxmo_notify_user.sh "$1 does not exist on the system"
		return 1
	fi
	if ! daemon_isrunning "$1"; then
		sxmo_notify_user.sh "$1 is already stopped"
		return 0
	fi
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
	if ! daemon_exists "$1"; then
		sxmo_log "$1 does not exist on the system"
		return 1
	fi
	case "$OS" in
		alpine|postmarketos)
			rc-service "$1" status | grep -q started
			;;
		arch|archarm|debian)
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
		arch|archarm|debian)
			[ "$1" = "modemmanager" ] && set -- ModemManager
			systemctl status "$1" > /dev/null 2>&1
			[ $? -ne 4 ]
			;;
	esac
}

case "$1" in
	start)

		sxmo_notify_user.sh "Starting modemmanager..."

		daemon_start modemmanager
		if ! daemon_isrunning modemmanager; then
			sxmo_notify_user.sh --urgency=critical "The modemmanager failed to start!"
			exit 1
		fi

		sxmo_notify_user.sh "Starting eg25-manager..."

		daemon_start eg25-manager
		if ! daemon_isrunning eg25-manager; then
			sxmo_notify_user.sh --urgency=critical "The eg25-manager failed to start!"
			exit 1
		fi

		sxmo_notify_user.sh --urgency=critical "Do not restart or reboot for 120s!"
		# blocks crust for 120s. see can_suspend
		sxmo_daemons.sh start modem_nocrust sleep 120

		sxmo_notify_user.sh "Finished starting modem daemons."
		;;
	stop)

		if sxmo_daemons.sh running modem_nocrust -q; then
			sxmo_notify_user.sh "Modem still warming up..."
			exit 1
		fi

		# stop eg25-manager first.
		# eg25-manager takes 30s to shutdown (which is unnecessary but will cause problems
		# if we try to start it within that period)
		# It is up to the user to put post_stop() { sleep 32 } in /etc/init.d/eg25-manager
		sxmo_notify_user.sh "Stopping eg25-manager. WARNING: please wait 30s before restarting."

		if ! daemon_stop eg25-manager; then
			sxmo_notify_user.sh --urgency=critical "The eg25-manager failed to stop!"
		fi

		sxmo_notify_user.sh "Stopping modemmanager..."

		if ! daemon_stop modemmanager; then
			sxmo-notify_user.sh --urgency=critical "The modemmanager failed to stop!"
		fi

		# according to biktorgj we need 2s to stop, so maybe roll this into post_stop() in init script
		sleep 2

		sxmo_notify_user.sh "Finished stopping daemons."
		;;
	status)
		daemon_isrunning eg25-manager || exit 1
		daemon_isrunning modemmanager || exit 1
		;;
esac
