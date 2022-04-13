#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=scripts/core/sxmo_common.sh
. /etc/profile.d/sxmo_init.sh

envvars() {
	export SXMO_WM=sway
	export MOZ_ENABLE_WAYLAND=1
	export SDL_VIDEODRIVER=wayland
	# shellcheck disable=SC2086
	command -v $TERMCMD "" >/dev/null || export TERMCMD="foot"
	command -v "$KEYBOARD" >/dev/null || export KEYBOARD=wvkbd-mobintl
	[ -z "$MOZ_USE_XINPUT2" ] && export MOZ_USE_XINPUT2=1
}

defaults() {
	[ -e "$HOME"/.Xresources ] && xrdb -merge "$HOME"/.Xresources
}

start() {
	# shellcheck disable=SC2016
	dbus-run-session sh -c '
		echo "$DBUS_SESSION_BUS_ADDRESS" > "$XDG_RUNTIME_DIR"/dbus.bus
		/usr/bin/sway -c "$XDG_CONFIG_HOME/sxmo/sway"
	'
}

cleanup() {
	sxmo_daemons.sh stop all # TODO: If I manage to remove all sxmo_daemons.sh calls. Remove this
	pkill superd
	pkill bemenu
	pkill wvkbd
}

init() {
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
