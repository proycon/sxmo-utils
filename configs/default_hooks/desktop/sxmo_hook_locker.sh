#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

sxmo_daemons.sh start idle_locker sxmo_idle.sh -w \
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

sxmo_hook_unlock.sh
