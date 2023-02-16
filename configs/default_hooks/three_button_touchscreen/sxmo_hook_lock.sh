#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

sxmo_log "transitioning to stage lock"
printf lock > "$SXMO_STATE"

# This hook is called when the system reaches a locked state

sxmo_uniq_exec.sh sxmo_led.sh blink blue &
sxmo_daemons.sh start state_change_bar sxmo_hook_statusbar.sh state_change

[ "$SXMO_WM" = "sway" ] && swaymsg mode default
sxmo_wm.sh dpms off
sxmo_wm.sh inputevent touchscreen off

# avoid dangling purple blinking when usb wakeup + power button…
sxmo_daemons.sh stop periodic_blink

# Go to screenoff after 8 seconds of inactivity
if ! [ -e "$XDG_CACHE_HOME/sxmo/sxmo.noidle" ]; then
	sxmo_daemons.sh start idle_locker sxmo_idle.sh -w \
		timeout 8 "sxmo_hook_screenoff.sh"
fi
