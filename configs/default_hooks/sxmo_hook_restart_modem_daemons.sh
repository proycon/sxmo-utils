#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script restart the modem-related daemons on the system
#  e.g., eg25-manager, modemmonitor, etc.

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

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
		arch|archarm|debian|nixos)
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
		arch|archarm|nixos)
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
		arch|archarm|debian|nixos)
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
		arch|archarm|debian|nixos)
			[ "$1" = "modemmanager" ] && set -- ModemManager
			systemctl status "$1" > /dev/null 2>&1
			[ $? -ne 4 ]
			;;
	esac
}

if command -v eg25-manager > /dev/null; then
	sxmo_notify_user.sh "Stopping eg25-manager..."
	daemon_stop eg25-manager
	sleep 2
	sxmo_notify_user.sh "Starting eg25-manager..."
	daemon_start eg25-manager
	if ! daemon_isrunning eg25-manager; then
		sxmo_notify_user.sh --urgency=critical "The eg25-manager failed to start!"
		exit 1
	fi
fi

sxmo_notify_user.sh "Stopping modemmanager..."
daemon_stop modemmanager
sleep 2
sxmo_notify_user.sh "Starting modemmanager..."
daemon_start modemmanager
if ! daemon_isrunning modemmanager; then
	sxmo_notify_user.sh --urgency=critical "The modemmanager failed to start!"
	exit 1
fi
# we want 120s before sleeping again
sxmo_wakelock.sh lock modem_manually_reset 120s
