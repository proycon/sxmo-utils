#!/usr/bin/env sh
source /etc/profile
which $TERM || export TERM=st
which $BROWSER || export BROWSER=surf

xsetroot -mod 3 2 -fg '#000000' -bg '#888888'
conky -c /usr/share/sxmo/conky.conf -d

sxmo_statusbar.sh &
xset r off
alsactl --file /usr/share/sxmo/default_alsa_sound.conf restore
exec dbus-run-session dwm 2> ~/.dwm.log
