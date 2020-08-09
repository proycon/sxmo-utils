#!/usr/bin/env sh
if [ -z "$1" ]; then
	exit 1
else
	CORNER="$1"
fi

if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/hotcorner_$CORNER" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/hotcorner_$CORNER"
	exit $?
fi

case "$CORNER" in
	"topleft")
		sxmo_appmenu.sh sys &
		;;
	"topright")
		;;
	"bottomleft")
		sxmo_lock.sh &
		;;
	"bottomright")
		sxmo_rotate.sh &
		;;
esac
