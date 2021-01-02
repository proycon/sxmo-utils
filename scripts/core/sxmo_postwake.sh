#!/usr/bin/env sh

# This script is called when the system has successfully woken up after sleep

sxmo_statusbarupdate.sh

(sleep 15 && sxmo_resetscaninterval.sh) &

if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/postwake" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/postwake"
fi
