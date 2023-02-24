#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

sxmo_log "going to suspend to crust"

YEARS8_TO_SEC=268435455
suspend_time=99999999 # far away

mnc="$(sxmo_hook_mnc.sh)"
if [ -n "$mnc" ] && [ "$mnc" -gt 0 ] && [ "$mnc" -lt "$YEARS8_TO_SEC" ]; then
	if [ "$mnc" -le 15 ]; then # cronjob imminent
		sxmo_wakelock.sh lock waiting_cronjob infinite
		exit 1
	else
		suspend_time=$((mnc - 10))
	fi
fi

sxmo_log "calling suspend with suspend_time <$suspend_time>"

start="$(date "+%s")"
rtcwake -m mem -s "$suspend_time" || exit 1
#We woke up again
time_spent="$(( $(date "+%s") - start ))"

if [ "$((time_spent + 15))" -ge "$suspend_time" ]; then
	sxmo_wakelock.sh lock waiting_cronjob infinite
fi

sxmo_hook_postwake.sh
