#!/usr/bin/env sh

# This script is called when the system has successfully woken up after sleep

sxmo_statusbarupdate.sh

if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/postwake" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/postwake"
fi
