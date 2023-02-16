#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

# This hook is called when the system reaches a off state (screen off)

sxmo_log "transitioning to stage off"
printf screenoff > "$SXMO_STATE"

sxmo_led.sh blink blue red &
sxmo_daemons.sh start state_change_bar sxmo_hook_statusbar.sh state_change

[ "$SXMO_WM" = "sway" ] && swaymsg mode default
sxmo_wm.sh dpms on
sxmo_wm.sh inputevent touchscreen off

case "$SXMO_WM" in
	dwm)
		# dmenu will grab input focus (i.e. power button) so kill it before going to
		# screenoff unless proximity lock is running (i.e. there's a phone call).
		if ! sxmo_daemons.sh running calling_proximity_lock -q; then
			sxmo_dmenu.sh close
		fi
		;;
esac

# Start a periodic daemon (8s) "try to go to crust" after 8 seconds
# Start a periodic daemon (2s) blink after 5 seconds
# Resume tasks stop daemons
sxmo_daemons.sh start idle_locker sxmo_idle.sh -w \
	timeout 8 'sxmo_daemons.sh start going_deeper sxmo_run_periodically.sh 30 sh -c "sxmo_uniq_exec.sh sxmo_hook_check_state_mutexes.sh && exec sxmo_mutex.sh can_suspend holdexec sxmo_suspend.sh"' \
	resume 'sxmo_daemons.sh stop going_deeper' \
	timeout 5 'sxmo_daemons.sh start periodic_blink sxmo_run_periodically.sh 2 sxmo_led.sh blink red blue' \
	resume 'sxmo_daemons.sh stop periodic_blink' \
	timeout 12 'sxmo_daemons.sh start periodic_state_mutex_check sxmo_run_periodically.sh 10 sxmo_uniq_exec.sh sxmo_hook_check_state_mutexes.sh' \
	resume 'sxmo_daemons.sh stop periodic_state_mutex_check'
