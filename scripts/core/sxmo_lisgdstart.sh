#!/usr/bin/env sh
pkill -9 lisgd

lisgd "$@" \
	-g '1,LR,sxmo_lisgdonefingercheck.sh xdotool key --clearmodifiers Alt+Shift+e' \
	-g '1,RL,sxmo_lisgdonefingercheck.sh xdotool key --clearmodifiers Alt+Shift+r' \
	-g '1,DLUR,sxmo_lisgdonefingercheck.sh sxmo_vol.sh up' \
	-g '1,URDL,sxmo_lisgdonefingercheck.sh sxmo_vol.sh down' \
	-g '1,DRUL,sxmo_lisgdonefingercheck.sh sxmo_brightness.sh up' \
	-g '1,ULDR,sxmo_lisgdonefingercheck.sh sxmo_brightness.sh down' \
	-g '2,LR,xdotool key --clearmodifiers Alt+e' \
	-g '2,RL,xdotool key --clearmodifiers Alt+r' \
	-g '2,DU,pidof svkbd-sxmo || svkbd-sxmo &' \
	-g '2,UD,pkill -9 svkbd-sxmo' \
	&
