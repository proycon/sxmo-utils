#!/usr/bin/env sh
# Env vars
# shellcheck disable=SC1091
. /etc/profile
command -v "$TERM" || export TERM=st
command -v "$BROWSER" || export BROWSER=surf
[ -z "$MOZ_USE_XINPUT2" ] && export MOZ_USE_XINPUT2=1
[ -z "$XDG_CONFIG_HOME" ] && export XDG_CONFIG_HOME=~/.config

# Setup audio and a few sensible X defaults
alsactl --file /usr/share/sxmo/alsa/default_alsa_sound.conf restore
xmodmap /usr/share/sxmo/appcfg/xmodmap_caps_esc
xsetroot -mod 3 2 -fg '#000000' -bg '#888888'
xset s off -dpms
xrdb /usr/share/sxmo/appcfg/xresources_xcalc.xr
synclient TapButton1=1 TapButton2=3 TapButton3=2 MinSpeed=0.25

# Start daemons
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

# Run user's custom xinit
set -o allexport
[ -f "$XDG_CONFIG_HOME/sxmo/xinit" ] && . "$XDG_CONFIG_HOME/sxmo/xinit"
set +o allexport

# Startup dbus, dunst in dbus path, lisgd in dbus path, and finally dwm
exec dbus-run-session sh -c "
	dunst -conf /usr/share/sxmo/appcfg/dunst.conf &
	sxmo_lisgdstart.sh &
	dwm 2> ~/.dwm.log
"
