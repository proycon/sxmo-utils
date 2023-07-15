#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

sxmo_wakelock.sh lock sxmo_not_screenoff infinite

# Go to locker after 5 minutes of inactivity
if [ -e "$XDG_CACHE_HOME/sxmo/sxmo.noidle" ]; then
	sxmo_daemons.sh stop idle_locker
else
	sxmo_daemons.sh start idle_locker sxmo_idle.sh -w \
		timeout 300 'sxmo_hook_locker.sh'
fi
