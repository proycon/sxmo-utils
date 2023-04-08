#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

set -e

last_check=0
wait_can_suspend() {
	# If we already checked recently, then there's nothing to do. This helps
	# mitigate the chance that running all checks could take too long and
	# cause suspend to fail.
	if [ "$((last_check + 10))" -gt "$(date +%s)" ]; then
		return
	fi

	sxmo_hook_block_suspend.sh

	last_check="$(date +%s)"
}

while true; do
	# Reading from wakeup_count blocks until there are no wakelocks
	wakeup_count=$(cat /sys/power/wakeup_count)

	wait_can_suspend

	# If the wakeup count has changed since we read it, this will fail so we
	# know to try again. If something takes a wake_lock after we do this, it
	# will cause the kernel to abort suspend.
	echo "$wakeup_count" > /sys/power/wakeup_count || continue

	# If sxmo_suspend failed then we didn't enter suspend, it should be safe
	# to retry immediately. There's a delay so we don't eat up all the
	# system resoures if the kernel can't suspend.
	if ! sxmo_suspend.sh; then
		sleep 1
		continue
	fi

	sleep 10
done
