#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=configs/profile.d/sxmo_init.sh
. /etc/profile.d/sxmo_init.sh

. sxmo_common.sh

# We can have multiple cronjobs at the same time
sxmo_wakelock.sh lock sxmo_executing_cronjob_$$ infinite
sxmo_wakelock.sh unlock sxmo_waiting_cronjob

finish() {
	if [ -n "$cmdpid" ]; then
		kill "$cmdpid" 2> /dev/null
	fi
	sxmo_wakelock.sh unlock sxmo_executing_cronjob_$$
	exit 0
}

trap 'finish' TERM INT EXIT

sxmo_log "Running $*"

"$@" &
cmdpid=$!
wait "$cmdpid"

unset cmdpid
