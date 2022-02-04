#!/bin/sh

# shellcheck source=scripts/core/sxmo_common.sh
. /etc/profile.d/sxmo_init.sh

envvars() {
	export SXMO_WM=sway
	export MOZ_ENABLE_WAYLAND=1
	export SDL_VIDEODRIVER=wayland
	# shellcheck disable=SC2086
	command -v $TERMCMD "" >/dev/null || export TERMCMD="foot"
	command -v "$BROWSER" >/dev/null || export BROWSER=firefox
	command -v "$EDITOR" >/dev/null || export EDITOR=vis
	command -v "$SHELL" >/dev/null || export SHELL=/bin/sh
	command -v "$KEYBOARD" >/dev/null || export KEYBOARD=wvkbd-mobintl
	[ -z "$MOZ_USE_XINPUT2" ] && export MOZ_USE_XINPUT2=1
	[ -z "$XDG_PICTURES_DIR" ] && export XDG_PICTURES_DIR=~/Pictures
}

defaults() {
	alsactl --file /usr/share/sxmo/alsa/default_alsa_sound.conf restore
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
	sxmo_daemons.sh stop all
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
	sxmo_hooks.sh stop
}

if [ -z "$1" ]; then
	init
else
	"$1"
fi
