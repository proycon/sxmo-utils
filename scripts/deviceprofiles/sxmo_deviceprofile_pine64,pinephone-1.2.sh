#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

export SXMO_WIFI_MODULE=8723cs
export SXMO_SYS_FILES="/sys/module/$SXMO_WIFI_MODULE/parameters/rtw_scan_interval_thr /sys/power/state /sys/devices/platform/soc/1f00000.rtc/power/wakeup /sys/power/mem_sleep /dev/rtc0 /sys/devices/platform/soc/1f03400.rsb/sunxi-rsb-3a3/axp221-pek/power/wakeup"
export SXMO_TOUCHSCREEN_ID=8
export SXMO_MONITOR="DSI-1"
export SXMO_ALSA_CONTROL_NAME=PinePhone
export SXMO_SWAY_SCALE="2"
