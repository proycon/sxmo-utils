#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This hook is called when the system becomes unlocked again

. sxmo_common.sh

sxmo_log "transitioning to stage unlock"
printf unlock > "$SXMO_STATE"

sxmo_hook_statusbar.sh state_change

sxmo_wm.sh dpms off
sxmo_wm.sh inputevent touchscreen on
sxmo_wm.sh inputevent stylus on
superctl start sxmo_hook_lisgd

# suspend after 30s
# the periodic mutex check is necessary to 'free' old mutex, I think.
if ! [ -e "$XDG_CACHE_HOME/sxmo/sxmo.nosuspend" ]; then
	sxmo_daemons.sh start idle_locker sxmo_idle.sh -w \
		timeout "${SXMO_UNLOCK_IDLE_TIME:-120}" 'sxmo_daemons.sh start crustin sxmo_run_periodically.sh 5 sh -c "sxmo_hook_check_state_mutexes.sh && exec sxmo_mutex.sh can_suspend holdexec sxmo_suspend.sh"' \
		resume 'sxmo_daemons.sh stop crustin' \
		timeout "$((${SXMO_UNLOCK_IDLE_TIME:-120}+10))" 'sxmo_daemons.sh start periodic_state_mutex_check sxmo_run_periodically.sh 10 sxmo_hook_check_state_mutexes.sh' \
		resume 'sxmo_daemons.sh stop periodic_state_mutex_check'
fi

sxmo_superd_signal.sh sxmo_desktop_widget -USR2
