#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

export SXMO_SYS_FILES="/sys/power/state /sys/power/mem_sleep /dev/rtc0"
export SXMO_TOUCHSCREEN_ID=7
export SXMO_MONITOR="DSI-1"
export SXMO_POWER_BUTTON="1:1:gpio-keys"
export SXMO_VOLUME_BUTTON="1:1:adc-keys"
export SXMO_MODEM_GPIO_KEY_RI="1:1:gpio-key-ri"
export SXMO_SWAY_SCALE="2"
