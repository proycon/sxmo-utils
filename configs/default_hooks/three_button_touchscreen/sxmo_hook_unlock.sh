#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

# This hook is called when the system becomes unlocked again

sxmo_wakelock.sh lock sxmo_not_screenoff infinite

sxmo_led.sh blink red green &

sxmo_wm.sh dpms off
sxmo_wm.sh inputevent touchscreen on

sxmo_jobs.sh stop periodic_blink
sxmo_jobs.sh stop periodic_wakelock_check

# Go to lock after 120 seconds of inactivity
if [ -e "$XDG_CACHE_HOME/sxmo/sxmo.noidle" ]; then
	sxmo_jobs.sh stop idle_locker
else
	case "$SXMO_WM" in
		sway)
			sxmo_jobs.sh start idle_locker sxmo_idle.sh -w \
				timeout "${SXMO_UNLOCK_IDLE_TIME:-120}" 'sh -c "
					swaymsg mode default;
					exec sxmo_state_switch.sh set lock
				"'
			;;
		dwm)
			sxmo_jobs.sh start idle_locker sxmo_idle.sh -w \
				timeout "${SXMO_UNLOCK_IDLE_TIME:-120}" "sxmo_state_switch.sh set lock"
			;;
	esac
fi

wait
