#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

UNSUSPENDREASON="$1"

#The UNSUSPENDREASON can be "usb power", "modem", "rtc" (real-time clock
#periodic wakeup) or "button". You will likely want to check against this and
#decide what to do

# stay awake if modem has crashed for 30s to give modem time to recover
modemloop() {
	echo "modem_crashed" | doas tee -a /sys/power/wake_lock > /dev/null
	sleep 30s
	echo "modem_crashed" | doas tee -a /sys/power/wake_unlock > /dev/null
}

if [ "$UNSUSPENDREASON" = "modem" ]; then
	MMCLI="$(mmcli -m any -J 2>/dev/null)"
	if [ -z "$MMCLI" ]; then
		sxmo_notify_user.sh --urgency=critical "Modem crashed! 30s recovery."
		modemloop &
	fi
fi

# see the comments in sxmo_hook_lock.sh
# and https://todo.sr.ht/~mil/sxmo-tickets/150
if [ 1 = "$SXMO_RTW_SCAN_INTERVAL" ]; then
	echo 1200 > "/sys/module/$SXMO_WIFI_MODULE/parameters/rtw_scan_interval_thr"
fi

if grep -q screenoff "$XDG_RUNTIME_DIR/sxmo.state"; then
	# We stopped it in presuspend
	sxmo_daemons.sh start periodic_blink sxmo_run_periodically.sh 2 sxmo_uniq_exec.sh sxmo_led.sh blink red blue
fi

# Add here whatever you want to do
