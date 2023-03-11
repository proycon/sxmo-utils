#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This hook is called when the system becomes unlocked again

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

sxmo_log "transitioning to stage unlock"
printf unlock > "$SXMO_STATE"

sxmo_wakelock.sh lock stay_awake "${SXMO_UNLOCK_IDLE_TIME:-120}s"

sxmo_hook_statusbar.sh state_change &

sxmo_wm.sh dpms off
sxmo_wm.sh inputevent touchscreen on
sxmo_wm.sh inputevent stylus on
superctl start sxmo_hook_lisgd

sxmo_daemons.sh start periodic_wakelock_check sxmo_run_periodically.sh 10 sxmo_hook_wakelocks.sh

# suspend after if no activity after 120s
sxmo_daemons.sh start idle_locker sxmo_idle.sh -w \
	timeout "1" '' \
	resume "sxmo_wakelock.sh lock stay_awake \"${SXMO_UNLOCK_IDLE_TIME:-120}s\""

wait
