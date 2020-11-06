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
	[ -z "$XDG_RUNTIME_HOME" ] && export XDG_RUNTIME_HOME=~/.local/run
	[ -z "$XDG_PICTURES_DIR" ] && export XDG_PICTURES_DIR=~/Pictures
}

setupxdgdir() {
	mkdir -p $XDG_RUNTIME_HOME
	chmod 700 $XDG_RUNTIME_HOME
	chown "$USER:$USER" "$XDG_RUNTIME_HOME"

	mkdir -p "$XDG_CACHE_HOME/sxmo/"
	chmod 700 "$XDG_CACHE_HOME"
	chown "$USER:$USER" "$XDG_CACHE_HOME"
}

xdefaults() {
	alsactl --file /usr/share/sxmo/alsa/default_alsa_sound.conf restore
	xmodmap /usr/share/sxmo/appcfg/xmodmap_caps_esc
	xsetroot -mod 29 29 -fg '#0b3a4c' -bg '#082430'
	xset s off -dpms
	xrdb /usr/share/sxmo/appcfg/xresources_xcalc.xr
	synclient TapButton1=1 TapButton2=3 TapButton3=2 MinSpeed=0.25
}

defaultkeyboard() {
	if command -v svkbd-mobile-intl; then
		export KEYBOARD=svkbd-mobile-intl
	elif command -v svkbd-mobile-plain; then
		export KEYBOARD=svkbd-mobile-plain
	else
		export KEYBOARD=svkbd-sxmo
	fi
}

daemons() {
	pkill conky
	if [ -e "$XDG_CONFIG_HOME/sxmo/conky.conf" ]; then
		conky -c $XDG_CONFIG_HOME/sxmo/conky.conf -d
	else
		conky -c /usr/share/sxmo/appcfg/conky.conf -d
	fi
	autocutsel &
	autocutsel -selection PRIMARY &
	sxmo_statusbar.sh &
}

daemonsneedingdbus() {
	dunst -conf /usr/share/sxmo/appcfg/dunst.conf &
	sxmo_notificationmonitor.sh &
	sxmo_lisgdstart.sh &
}

customxinit() {
	set -o allexport
	# shellcheck disable=SC1090
	[ -f "$XDG_CONFIG_HOME/sxmo/xinit" ] && . "$XDG_CONFIG_HOME/sxmo/xinit"
	set +o allexport
}

startdwm() {

	exec dbus-run-session sh -c "
		$0 daemonsneedingdbus;
		. $0 customxinit;
		dwm 2> "$XDG_CACHE_HOME/sxmo/dwm.log"
	"
}

xinit() {
	envvars
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
