#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

sxmo_jobs.sh start idle_locker sxmo_idle.sh -w \
	timeout 10 'sxmo_wm.sh dpms on' \
		resume 'sxmo_wm.sh dpms off'

case "$SXMO_WM" in
	sway)
		swaylockd
		;;
	dwm)
		i3lock
		;;
esac

# need & cause we are still holding flock
sxmo_state_switch.sh set unlock &
