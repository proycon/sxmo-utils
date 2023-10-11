#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script have to be sourced from other session init scripts.
# The scripts have to implement envvars, defaults, with_dbus, and cleanup
# methods. See sxmo_winit.sh as example.

start() {
	[ -f "$XDG_STATE_HOME"/sxmo.log ] && mv "$XDG_STATE_HOME"/sxmo.log "$XDG_STATE_HOME"/sxmo.log.old

	if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
		dbus-run-session -- "$0" "with_dbus"
	else
		# with_dbus calls exec because dbus-run-session starts it in a
		# new shell, but we need to keep this shell; start a subshell
		( with_dbus )
	fi
}

init() {
	# shellcheck source=/dev/null
	. /etc/profile.d/sxmo_init.sh

	_sxmo_load_environments
	_sxmo_prepare_dirs
	envvars
	sxmo_migrate.sh sync

	defaults

	# shellcheck disable=SC1090,SC1091
	. "$XDG_CONFIG_HOME/sxmo/profile"

	cleanup
	start
	cleanup
	sxmo_hook_stop.sh
}

if [ -z "$1" ]; then
	init
else
	"$1"
fi
