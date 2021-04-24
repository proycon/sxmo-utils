#!/usr/bin/env sh


envvars() {
	# shellcheck disable=SC1091
	[ -f /etc/profile ] && . /etc/profile
	# shellcheck source=/dev/null
	[ -f "$HOME"/.profile ] && . "$HOME"/.profile
	command -v "$TERMCMD" || export TERMCMD=st
	command -v "$BROWSER" || export BROWSER=surf
	command -v "$EDITOR" || export EDITOR=vis
	command -v "$SHELL" || export SHELL=/bin/sh
	command -v "$KEYBOARD" || defaultkeyboard
	[ -z "$MPV_HOME" ] && export MPV_HOME=/usr/share/sxmo/mpv
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
	synclient TapButton1=1 TapButton2=3 TapButton3=2 MinSpeed=0.25
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
	sxmo_lisgdstart.sh &
}

defaultconfig() {
	#this is only run on the very first start of sxmo

	mkdir -p "$XDG_CONFIG_HOME/sxmo"
	cp /usr/share/sxmo/appcfg/xinit_template "$XDG_CONFIG_HOME/sxmo/xinit"
	chmod u+rx "$XDG_CONFIG_HOME/sxmo/xinit"

	#Set some default hooks
	mkdir -p "$XDG_CONFIG_HOME/sxmo/hooks"
	if [ ! -e "$XDG_CONFIG_HOME/sxmo/hooks/ring" ]; then
		cp /usr/share/sxmo/default_hooks/ring "$XDG_CONFIG_HOME/sxmo/hooks/ring"
		chmod u+rx "$XDG_CONFIG_HOME/sxmo/hooks/ring"
	fi
	if [ ! -e "$XDG_CONFIG_HOME/sxmo/hooks/sms" ]; then
		cp /usr/share/sxmo/default_hooks/sms "$XDG_CONFIG_HOME/sxmo/hooks/sms"
		chmod u+rx "$XDG_CONFIG_HOME/sxmo/hooks/sms"
	fi
	if [ ! -e "$XDG_CONFIG_HOME/sxmo/hooks/pickup" ]; then
		cp /usr/share/sxmo/default_hooks/pickup "$XDG_CONFIG_HOME/sxmo/hooks/pickup"
		chmod u+rx "$XDG_CONFIG_HOME/sxmo/hooks/pickup"
	fi
	if [ ! -e "$XDG_CONFIG_HOME/sxmo/hooks/missed_call" ]; then
		cp /usr/share/sxmo/default_hooks/missed_call "$XDG_CONFIG_HOME/sxmo/hooks/missed_call"
		chmod u+rx "$XDG_CONFIG_HOME/sxmo/hooks/missed_call"
	fi
}

customxinit() {
	set -o allexport
	# shellcheck disable=SC1090
	[ ! -e "$XDG_CONFIG_HOME/sxmo/xinit" ] && defaultconfig

	# shellcheck disable=SC1090
	. "$XDG_CONFIG_HOME/sxmo/xinit"
	set +o allexport
}

startdwm() {

	exec dbus-run-session sh -c "
		$0 daemonsneedingdbus;
		. $0 customxinit;
		dwm 2> "$CACHEDIR/dwm.log"
	"
}

xinit() {
	# include common definitions
	# shellcheck source=scripts/core/sxmo_common.sh
	. "$(dirname "$0")/sxmo_common.sh"

	envvars
	# set device env vars here to allow potentially overriding envvars
	device_envvars
	setupxdgdir
	xdefaults
	daemons
	startdwm
}

if [ -z "$1" ]; then
	xinit
else
	"$1"
fi
