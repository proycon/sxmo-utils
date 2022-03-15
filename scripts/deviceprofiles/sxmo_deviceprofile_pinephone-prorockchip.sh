#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

export SXMO_SYS_FILES="/sys/module/8723cs/parameters/rtw_scan_interval_thr /sys/power/state /sys/devices/platform/soc/1f00000.rtc/power/wakeup /sys/power/mem_s
eep /sys/bus/usb/drivers/usb/unbind /sys/bus/usb/drivers/usb/bind /dev/rtc0 /sys/devices/platform/soc/1f03400.rsb/sunxi-rsb-3a3/axp221-pek/power/wakeup"
export SXMO_TOUCHSCREEN_ID=8
export SXMO_POWER_BUTTON="1:1:gpio-key-power"
export SXMO_VOLUME_BUTTON="1:1:adc-keys"
