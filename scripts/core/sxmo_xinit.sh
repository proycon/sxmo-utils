#!/usr/bin/env sh
# Env vars
# shellcheck disable=SC1091
. /etc/profile
command -v "$TERM" || export TERM=st
command -v "$BROWSER" || export BROWSER=surf
[ -z "$MOZ_USE_XINPUT2" ] && export MOZ_USE_XINPUT2=1
[ -z "$XDG_CONFIG_HOME" ] && export XDG_CONFIG_HOME=~/.config

# Setup audio and a few sensible X defaults
alsactl --file /usr/share/sxmo/default_alsa_sound.conf restore
xmodmap /usr/share/sxmo/xmodmap_caps_esc
xsetroot -mod 3 2 -fg '#000000' -bg '#888888'
xset s off -dpms
xrdb /usr/share/sxmo/xresources_xcalc.xr
synclient TapButton1=1 TapButton2=3 TapButton3=2 MinSpeed=0.25

# Kill old hanging daemons
pkill lisgd && pkill conky

# Start daemons
conky -c /usr/share/sxmo/conky.conf -d
keynav &
autocutsel &
autocutsel -selection PRIMARY &
sxmo_statusbar.sh &

# Run user's custom xinit
[ -f "$XDG_CONFIG_HOME/sxmo/xinit" ] && "$XDG_CONFIG_HOME/sxmo/xinit"

# Startup dbus, dunst in dbus path, lisgd in dbus path, and finally dwm
exec dbus-run-session sh -c "
	dunst -conf /usr/share/sxmo/dunst.conf &
	lisgd &
	dwm 2> ~/.dwm.log
"
