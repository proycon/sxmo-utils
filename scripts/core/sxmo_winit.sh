#!/bin/sh

envvars() {
	export SXMO_WM=sway
	export MOZ_ENABLE_WAYLAND=1
	export SDL_VIDEODRIVER=wayland
	# shellcheck disable=SC2086
	command -v $TERMCMD || export TERMCMD="foot"
	command -v "$BROWSER" || export BROWSER=firefox
	command -v "$EDITOR" || export EDITOR=vis
	command -v "$SHELL" || export SHELL=/bin/sh
	command -v "$KEYBOARD" || export KEYBOARD=wvkbd-mobintl
	[ -z "$MOZ_USE_XINPUT2" ] && export MOZ_USE_XINPUT2=1
	[ -z "$XDG_PICTURES_DIR" ] && export XDG_PICTURES_DIR=~/Pictures
}

defaults() {
	alsactl --file /usr/share/sxmo/alsa/default_alsa_sound.conf restore
	[ -e "$HOME"/.Xresources ] && xrdb -merge "$HOME"/.Xresources
}

defaultconfig() {
	if [ ! -r "$2" ]; then
		mkdir -p "$(dirname "$2")"
		cp "$1" "$2"
		chmod "$3" "$2"
	fi
}

defaultconfigs() {
	defaultconfig /usr/share/sxmo/appcfg/profile_template "$XDG_CONFIG_HOME/sxmo/profile" 744
	defaultconfig /usr/share/sxmo/appcfg/sway_template "$XDG_CONFIG_HOME/sxmo/sway" 744
	defaultconfig /usr/share/sxmo/appcfg/mako.conf "$XDG_CONFIG_HOME/mako/config" 744
	defaultconfig /usr/share/sxmo/appcfg/foot.ini "$XDG_CONFIG_HOME/foot/foot.ini" 744
}

start() {
	[ -f "$XDG_CACHE_HOME/sxmo/sxmo.log" ] && mv -f "$XDG_CACHE_HOME/sxmo/sxmo.log" "$XDG_CACHE_HOME/sxmo/sxmo.previous.log"
	dbus-run-session sh -c "
		/usr/bin/sway -c \"$XDG_CONFIG_HOME/sxmo/sway\"
	" 2> "$DEBUGLOG"
}

cleanup() {
	sxmo_daemons.sh stop all
	pkill bemenu
	pkill wvkbd
}

init() {
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
	init 2> ~/.init.log #hard-coded location because at this stage we're not sure the xdg dirs exist yet
else
	"$1"
fi
