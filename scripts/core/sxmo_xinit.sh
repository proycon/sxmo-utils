#!/usr/bin/env sh
source /etc/profile
which $TERM || export TERM=st
which $BROWSER || export BROWSER=surf
[ -z "$MOZ_USE_XINPUT2" ] && export MOZ_USE_XINPUT2=1

xmodmap /usr/share/sxmo/xmodmap_caps_esc
xsetroot -mod 3 2 -fg '#000000' -bg '#888888'
xset s off -dpms
alsactl --file /usr/share/sxmo/default_alsa_sound.conf restore
#xset r off

# Xresources
xrdb /usr/share/sxmo/xresources_xcalc.xr

# E.g. for PBP
synclient TapButton1=1 TapButton2=3 TapButton3=2 MinSpeed=0.25
keynav &

conky -c /usr/share/sxmo/conky.conf -d
autocutsel & autocutsel -selection PRIMARY &
sxmo_statusbar.sh &
exec dbus-run-session sh -c "dunst -conf /usr/share/sxmo/dunst.conf & lisgd -t 500 & dwm 2> ~/.dwm.log"
