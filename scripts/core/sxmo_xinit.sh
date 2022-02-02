#!/bin/sh

# shellcheck source=scripts/core/sxmo_common.sh
. /etc/profile.d/sxmo_init.sh

envvars() {
	export SXMO_WM=dwm
	# shellcheck disable=SC2086
	command -v $TERMCMD "" >/dev/null || export TERMCMD="st"
	command -v "$BROWSER" >/dev/null || export BROWSER=surf
	command -v "$EDITOR" >/dev/null || export EDITOR=vis
	command -v "$SHELL" >/dev/null || export SHELL=/bin/sh
	command -v "$KEYBOARD" >/dev/null || defaultkeyboard
	[ -z "$MOZ_USE_XINPUT2" ] && export MOZ_USE_XINPUT2=1
	[ -z "$XDG_PICTURES_DIR" ] && export XDG_PICTURES_DIR=~/Pictures
}

defaults() {
	alsactl --file /usr/share/sxmo/alsa/default_alsa_sound.conf restore
	xmodmap /usr/share/sxmo/appcfg/xmodmap_caps_esc
	xsetroot -mod 29 29 -fg '#0b3a4c' -bg '#082430'
	xset s off -dpms
	for xr in /usr/share/sxmo/appcfg/*.xr; do
		xrdb -merge "$xr"
	done
	[ -e "$HOME"/.Xresources ] && xrdb -merge "$HOME"/.Xresources
	SCREENWIDTH=$(xrandr | grep "Screen 0" | cut -d" " -f 8)
	SCREENHEIGHT=$(xrandr | grep "Screen 0" | cut -d" " -f 10 | tr -d ",")
	if [ "$SCREENWIDTH" -lt 1024 ] || [ "$SCREENHEIGHT" -lt 768 ]; then
		gsettings set org.gtk.Settings.FileChooser window-size "($SCREENWIDTH,$((SCREENHEIGHT / 2)))"
	fi
}

defaultkeyboard() {
	if command -v svkbd-mobile-intl >/dev/null; then
		export KEYBOARD=svkbd-mobile-intl
	elif command -v svkbd-mobile-plain >/dev/null; then
		export KEYBOARD=svkbd-mobile-plain
	else
		#legacy
		export KEYBOARD=svkbd-sxmo
	fi
}

defaultconfig() {
	if [ ! -r "$2" ]; then
		mkdir -p "$(dirname "$2")"
		cp "$1" "$2"
		chmod "$3" "$2"
	fi
}

defaultconfigs() {
	defaultconfig /usr/share/sxmo/appcfg/profile_template "$XDG_CONFIG_HOME/sxmo/profile" 644
	defaultconfig /usr/share/sxmo/appcfg/dunst.conf "$XDG_CONFIG_HOME/dunst/dunstrc" 644
}

start() {
	# shellcheck disable=SC2016
	dbus-run-session sh -c '
		echo "$DBUS_SESSION_BUS_ADDRESS" > "$XDG_RUNTIME_DIR"/dbus.bus
		. "$XDG_CONFIG_HOME"/sxmo/xinit
		dwm
	'
}

cleanup() {
	sxmo_daemons.sh stop all
	pkill svkbd
	pkill dmenu
}

init() {
	_sxmo_load_environments
	_sxmo_prepare_dirs
	_sxmo_check_and_move_config
	envvars

	defaults
	defaultconfigs

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
