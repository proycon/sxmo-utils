#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

export SXMO_SPEAKER="Speaker"
export SXMO_HEADPHONE="Headphone"
export SXMO_EARPIECE="Earpiece"
export SXMO_LED_RED_TYPE="status"
export SXMO_LED_GREEN_TYPE="status"
export SXMO_LED_BLUE_TYPE="status"
export SXMO_LED_WHITE_TYPE="torch"
export SXMO_SYS_FILES="/sys/power/state /sys/power/mem_sleep /sys/bus/usb/drivers/usb/unbind /sys/bus/usb/drivers/usb/bind /dev/rtc0"
export SXMO_POWER_BUTTON="0:0:30370000.snvs:snvs-powerkey"
export SXMO_VOLUME_BUTTON="1:1:gpio-keys"
