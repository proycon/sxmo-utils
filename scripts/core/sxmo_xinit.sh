#!/bin/sh

envvars() {
	export SXMO_WM=dwm
	# shellcheck disable=SC2086
	command -v $TERMCMD "" || export TERMCMD="st"
	command -v "$BROWSER" || export BROWSER=surf
	command -v "$EDITOR" || export EDITOR=vis
	command -v "$SHELL" || export SHELL=/bin/sh
	command -v "$KEYBOARD" || defaultkeyboard
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
	if command -v svkbd-mobile-intl; then
		export KEYBOARD=svkbd-mobile-intl
	elif command -v svkbd-mobile-plain; then
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
	defaultconfig /usr/share/sxmo/appcfg/profile_template "$XDG_CONFIG_HOME/sxmo/profile" 744
	defaultconfig /usr/share/sxmo/appcfg/dunst.conf "$XDG_CONFIG_HOME/dunst/dunstrc" 744
}

customxinit() {
	set -o allexport

	# shellcheck disable=SC1090,SC1091
	. "$XDG_CONFIG_HOME/sxmo/xinit"
	set +o allexport
}

start() {
	[ -f "$XDG_CACHE_HOME/sxmo/sxmo.log" ] && mv -f "$XDG_CACHE_HOME/sxmo/sxmo.log" "$XDG_CACHE_HOME/sxmo/sxmo.previous.log"
	dbus-run-session sh -c "
		set -- customxinit
		. $0
		dwm
	" 2> "$DEBUGLOG"
}

cleanup() {
	sxmo_daemons.sh stop all
	pkill svkbd
	pkill dmenu
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
