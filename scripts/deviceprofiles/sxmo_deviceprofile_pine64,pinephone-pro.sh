#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

export SXMO_SYS_FILES="/sys/power/state /sys/power/mem_sleep /sys/bus/usb/drivers/usb/unbind /sys/bus/usb/drivers/usb/bind /dev/rtc0"
export SXMO_TOUCHSCREEN_ID=7
export SXMO_MONITOR="DSI-1"
export SXMO_POWER_BUTTON="1:1:gpio-key-power"
export SXMO_VOLUME_BUTTON="1:1:adc-keys"
export SXMO_MODEMRTC=12
export SXMO_POWERRTC=5
export SXMO_WAKEUPRTC=3
export SXMO_EG25=1
