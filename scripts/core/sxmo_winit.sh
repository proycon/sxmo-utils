#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

envvars() {
	export SXMO_WM=sway
	export MOZ_ENABLE_WAYLAND=1
	export SDL_VIDEODRIVER=wayland
	export XDG_CURRENT_DESKTOP=sway
	# shellcheck disable=SC2086
	command -v $TERMCMD "" >/dev/null || export TERMCMD="foot"
	command -v "$KEYBOARD" >/dev/null || export KEYBOARD=wvkbd-mobintl
	[ -z "$MOZ_USE_XINPUT2" ] && export MOZ_USE_XINPUT2=1
}

defaults() {
	[ -e "$HOME"/.Xresources ] && xrdb -merge "$HOME"/.Xresources
}

with_dbus() {
	echo "$DBUS_SESSION_BUS_ADDRESS" > "$XDG_RUNTIME_DIR"/dbus.bus
	exec sway -c "$XDG_CONFIG_HOME/sxmo/sway"
}

start() {
	if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
		dbus-run-session -- "$0" "with_dbus"
	else
		# with_dbus calls exec because dbus-run-session starts it in a
		# new shell, but we need to keep this shell; start a subshell
		( with_dbus )
	fi
}

cleanup() {
	sxmo_daemons.sh stop all
	pkill bemenu
	pkill wvkbd
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

	start
	cleanup
	sxmo_hook_stop.sh
}

if [ -z "$1" ]; then
	init
else
	"$1"
fi
