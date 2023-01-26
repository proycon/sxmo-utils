#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

# This hook is called when the system becomes unlocked again

sxmo_log "transitioning to stage unlock"
printf unlock > "$SXMO_STATE"

sxmo_uniq_exec.sh sxmo_led.sh blink red green &
sxmo_daemons.sh start state_change_bar sxmo_hook_statusbar.sh state_change

sxmo_wm.sh dpms off
sxmo_wm.sh inputevent touchscreen on
superctl start sxmo_hook_lisgd

# avoid dangling purple blinking when usb wakeup + power button…
sxmo_daemons.sh stop periodic_blink

# see https://todo.sr.ht/~mil/sxmo-tickets/150
# We set the scan interval threshold here to
# 16000 (16s) the default, since in sxmo_hook_postwake.sh
# we set it to 1200 (.12s) so that we can reconnect to wifi
# quicker after resuming from suspend.
if [ 1 = "$SXMO_RTW_SCAN_INTERVAL" ]; then
	echo 16000 > "/sys/module/$SXMO_WIFI_MODULE/parameters/rtw_scan_interval_thr"
fi

# Go to lock after 120 seconds of inactivity
if [ -e "$XDG_CACHE_HOME/sxmo/sxmo.noidle" ]; then
	sxmo_daemons.sh stop idle_locker
else
	case "$SXMO_WM" in
		sway)
			sxmo_daemons.sh start idle_locker sxmo_idle.sh -w \
				timeout "${SXMO_UNLOCK_IDLE_TIME:-120}" 'sh -c "
					swaymsg mode default;
					exec sxmo_hook_lock.sh
				"'
			;;
		dwm)
			sxmo_daemons.sh start idle_locker sxmo_idle.sh -w \
				timeout "${SXMO_UNLOCK_IDLE_TIME:-120}" "sxmo_hook_lock.sh"
			;;
	esac
fi

sxmo_daemons.sh start periodic_state_mutex_check \
	sxmo_run_aligned.sh 60 sxmo_uniq_exec.sh sxmo_hook_check_state_mutexes.sh
