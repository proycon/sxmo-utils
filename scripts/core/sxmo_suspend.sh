#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

sxmo_log "going to suspend to crust"

if suspend_time="$(sxmo_hook_mnc.sh)"; then
	sxmo_log "calling suspend with suspend_time <$suspend_time>"

	start="$(date "+%s")"
	rtcwake -m mem -s "$suspend_time" || exit 1

	#We woke up again
	time_spent="$(( $(date "+%s") - start ))"

	if [ "$suspend_time" -gt 0 ] && [ "$((time_spent + 10))" -ge "$suspend_time" ]; then
		UNSUSPENDREASON="rtc"
	fi
else
	sxmo_log "fake suspend (suspend_time ($suspend_time) less than zero)"
	UNSUSPENDREASON=rtc # we fake the crust for those seconds
fi

if [ "$UNSUSPENDREASON" = "rtc" ]; then
	sxmo_wakelock.sh lock waiting_cronjob infinite
fi

sxmo_hook_postwake.sh
