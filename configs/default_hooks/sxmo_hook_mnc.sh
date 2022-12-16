#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

. sxmo_common.sh

YEARS8_TO_SEC=268435455

if ! command -v mnc > /dev/null; then
	exit 0
fi

time="$(crontab -l | grep sxmo_rtcwake | mnc)"

# don't return time if it's too far in the future
if [ "$time" -ge "$YEARS8_TO_SEC" ]; then
	exit 0
fi

# Exit status 1 indicates that there is a cron job soon
if [ "$time" -lt 10 ]; then
	sxmo_log "next cron time ($time) is too soon"
	exit 1
fi

echo "$((time - 10))"
