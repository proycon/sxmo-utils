#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=configs/profile.d/sxmo_init.sh
. /etc/profile.d/sxmo_init.sh

. sxmo_common.sh

# We can have multiple cronjobs at the same time
echo "executing_cronjob" | doas tee -a /sys/power/wake_lock > /dev/null
echo "waiting_cronjob" | doas tee -a /sys/power/wake_unlock > /dev/null

finish() {
	echo "executing_cronjob" | doas tee -a /sys/power/wake_unlock > /dev/null
	exit 0
}

trap 'finish' TERM INT EXIT

sxmo_log "Running $*"
"$@"
