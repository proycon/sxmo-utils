#!/usr/bin/env sh
if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/lock" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/lock"
fi
pkill -9 lisgd
sxmo_screenlock "$@"
sxmo_lisgdstart.sh &
if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/unlock" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/unlock"
fi
