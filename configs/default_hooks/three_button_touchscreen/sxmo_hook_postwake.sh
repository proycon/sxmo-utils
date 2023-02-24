#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

MMCLI="$(mmcli -m any -J 2>/dev/null)"
if [ -z "$MMCLI" ]; then
	sxmo_notify_user.sh --urgency=critical "Modem crashed! 30s recovery."
	sxmo_wakelock.sh lock modem_crashed 30000000000
fi

# see the comments in sxmo_hook_lock.sh
# and https://todo.sr.ht/~mil/sxmo-tickets/150
if [ 1 = "$SXMO_RTW_SCAN_INTERVAL" ]; then
	echo 1200 > "/sys/module/$SXMO_WIFI_MODULE/parameters/rtw_scan_interval_thr"
fi

# Add here whatever you want to do
