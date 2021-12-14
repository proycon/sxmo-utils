#!/usr/bin/env sh


envvars() {
	# shellcheck disable=SC1091
	[ -f /etc/profile ] && . /etc/profile
	export SXMO_WM=dwm
	command -v "$TERMCMD" || export TERMCMD="st -e"
	command -v "$BROWSER" || export BROWSER=surf
	command -v "$EDITOR" || export EDITOR=vis
	command -v "$SHELL" || export SHELL=/bin/sh
	command -v "$KEYBOARD" || defaultkeyboard
	# shellcheck source=/dev/null
	[ -f "$HOME"/.profile ] && . "$HOME"/.profile
	[ -z "$MOZ_USE_XINPUT2" ] && export MOZ_USE_XINPUT2=1
	[ -z "$XDG_CONFIG_HOME" ] && export XDG_CONFIG_HOME=~/.config
	[ -z "$XDG_CACHE_HOME" ] && export XDG_CACHE_HOME=~/.cache
	[ -z "$XDG_DATA_HOME" ] && export XDG_DATA_HOME=~/.local/share
	[ -z "$XDG_RUNTIME_DIR" ] && export XDG_RUNTIME_DIR=~/.local/run
	[ -z "$XDG_PICTURES_DIR" ] && export XDG_PICTURES_DIR=~/Pictures
}

device_envvars() {
	device="$(cut -d ',' -f 2 < /sys/firmware/devicetree/base/compatible)"
	deviceprofile="$(which "sxmo_deviceprofile_$device.sh")"
	# shellcheck disable=SC1090
	[ -f "$deviceprofile" ] && . "$deviceprofile"
}

setupxdgdir() {
	mkdir -p $XDG_RUNTIME_DIR
	chmod 700 $XDG_RUNTIME_DIR
	chown "$USER:$USER" "$XDG_RUNTIME_DIR"

	mkdir -p "$XDG_CACHE_HOME/sxmo/"
	chmod 700 "$XDG_CACHE_HOME"
	chown "$USER:$USER" "$XDG_CACHE_HOME"
}

xdefaults() {
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

daemons() {
	autocutsel &
	autocutsel -selection PRIMARY &
	sxmo_statusbar.sh &
}

daemonsneedingdbus() {
	dunst -conf /usr/share/sxmo/appcfg/dunst.conf &
	sxmo_notificationmonitor.sh &
	sxmo_networkmonitor.sh &
	sxmo_hooks.sh lisgdstart &
}

defaultconfig() {
	if [ ! -r "$2" ]; then
		mkdir -p "$(dirname "$2")"
		cp "$1" "$2"
		chmod "$3" "$2"
	fi
}

defaultconfigs() {
	[ -r "$XDG_CONFIG_HOME/sxmo/xinit" ] && return

	defaultconfig /usr/share/sxmo/appcfg/xinit_template "$XDG_CONFIG_HOME/sxmo/xinit" 744
}

customxinit() {
	set -o allexport
	defaultconfigs

	# shellcheck disable=SC1090,SC1091
	. "$XDG_CONFIG_HOME/sxmo/xinit"
	set +o allexport
}

startdwm() {
	[ -f "$XDG_CACHE_HOME/sxmo/sxmo.log" ] && mv -f "$XDG_CACHE_HOME/sxmo/sxmo.log" "$XDG_CACHE_HOME/sxmo/sxmo.previous.log"
	dbus-run-session sh -c "
		set -- customxinit
		. $0
		$0 daemonsneedingdbus
		dwm
	" 2> "$XDG_CACHE_HOME/sxmo/sxmo.log"
}

stopdwm() {
	pkill -f sxmo_rotateautotoggle.sh
	pkill -f sxmo_notificationmonitor.sh
	pkill -f sxmo_networkmonitor.sh
	pkill lisgd

	pkill svkbd
	pkill conky
	pkill dmenu
}

xinit() {
	envvars
	device_envvars # set device env vars here to allow potentially overriding envvars

	# include common definitions
	# shellcheck source=scripts/core/sxmo_common.sh
	. "$(dirname "$0")/sxmo_common.sh"

	setupxdgdir
	xdefaults
	daemons
	startdwm
	stopdwm
	sxmo_hooks.sh stop
}

if [ -z "$1" ]; then
	xinit 2> ~/.xinit.log #hard-coded location because at this stage we're not sure the xdg dirs exist yet
else
	"$1"
fi
