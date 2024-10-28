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
		sxmo_wakelock.sh lock sxmo_waiting_cronjob infinite
		exit 1
	else
		suspend_time=$((mnc - 10))
	fi
fi


if [ "$SXMO_DEVICE_NAME" = "google,b4s4-sdm670" ]; then #(google pixel 3a)
	# Quoting Richard Acayan from: https://gitlab.postmarketos.org/postmarketOS/pmaports/-/merge_requests/5400/ :
	#
	# There is a bug in FastRPC when waking from suspend. Since HexagonRPCD is
	# currently only useful for a few moments when the ADSP is requesting the
	# sensor registry, it can just be stopped without affecting sensor
	# support. Add a pre-suspend hook to stop HexagonRPCD so it doesn't crash
	# the ADSP when the device wakes up.
	#
	case "$SXMO_OS" in
		alpine|postmarketos)
			doas -n rc-service hexagonrpcd-adsp-sensorspd stop
			;;
		arch|archarm|nixos|debian)
			doas -n systemctl stop hexagonrpcd-adsp-sensorspd
			;;
	esac
fi

sxmo_log "calling suspend with suspend_time <$suspend_time>"

start="$(date "+%s")"
doas rtcwake -m mem -s "$suspend_time" || exit 1
#We woke up again
time_spent="$(( $(date "+%s") - start ))"

if [ "$((time_spent + 15))" -ge "$suspend_time" ]; then
	sxmo_wakelock.sh lock sxmo_waiting_cronjob infinite
fi

sxmo_hook_postwake.sh
