#!/usr/bin/env sh

envvars() {
	# shellcheck disable=SC1091
	. /etc/profile
	command -v "$TERM" || export TERM=st
	command -v "$BROWSER" || export BROWSER=surf
	command -v "$EDITOR" || export EDITOR=vis
	command -v "$KEYBOARD" || export KEYBOARD=svkbd-sxmo
	[ -z "$MOZ_USE_XINPUT2" ] && export MOZ_USE_XINPUT2=1
	[ -z "$XDG_CONFIG_HOME" ] && export XDG_CONFIG_HOME=~/.config
	[ -z "$XDG_CACHE_HOME" ] && export XDG_CACHE_HOME=~/.cache
	[ -z "$XDG_DATA_HOME" ] && export XDG_DATA_HOME=~/.local/share
	[ -z "$XDG_RUNTIME_HOME" ] && export XDG_RUNTIME_HOME=~/.local/run
}

setupxdgruntimedir() {
	mkdir -p $XDG_RUNTIME_HOME
	chmod 700 $XDG_RUNTIME_HOME
	chown "$USER:$USER" "$XDG_RUNTIME_HOME"
}

xdefaults() {
	alsactl --file /usr/share/sxmo/alsa/default_alsa_sound.conf restore
	xmodmap /usr/share/sxmo/appcfg/xmodmap_caps_esc
	xsetroot -mod 3 2 -fg '#000000' -bg '#888888'
	xset s off -dpms
	xrdb /usr/share/sxmo/appcfg/xresources_xcalc.xr
	synclient TapButton1=1 TapButton2=3 TapButton3=2 MinSpeed=0.25
}

daemons() {
	pkill conky
	if [ -e "$XDG_CONFIG_HOME/sxmo/conky.conf" ]; then
		conky -c $XDG_CONFIG_HOME/sxmo/conky.conf -d
	else
		conky -c /usr/share/sxmo/appcfg/conky.conf -d
	fi
	keynav &
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
		dwm 2> ~/.dwm.log
	"
}

xinit() {
	envvars
	setupxdgruntimedir
	xdefaults
	daemons
	startdwm
}

if [ -z "$1" ]; then
	xinit
else
	"$1"
fi
