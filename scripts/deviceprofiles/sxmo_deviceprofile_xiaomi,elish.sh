#!/bin/sh
# mi pad 5 pro
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

export SXMO_DISABLE_LEDS="1"
export SXMO_MONITOR="0:0:NVTCapacitiveTouchScreen"
export SXMO_POWER_BUTTON="0:0:pm8941_pwrkey"
export SXMO_VOLUME_BUTTON="1:1:gpio-keys 0:0:pm8941_resin"
#export SXMO_SWAY_SCALE=""
#export SXMO_VIBRATE_DEV=""
