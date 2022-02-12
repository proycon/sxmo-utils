#!/bin/sh

# Go to locker after 5 minutes of inactivity
if ! [ -e "$XDG_CACHE_HOME/sxmo/sxmo.noidle" ]; then
	sxmo_daemons.sh start idle_locker sxmo_idle.sh -w \
		timeout 300 'sxmo_hook_locker.sh'
fi
