#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2024 Sxmo Contributors

export SXMO_VOLUME_BUTTON="1:1:gpio-keys 0:0:pm8941_resin"
export SXMO_POWER_BUTTON="0:0:pm8941_pwrkey"
export SXMO_VIBRATE_DEV="/dev/input/event2"
export SXMO_VIBRATE_STRENGTH="50000"
export SXMO_SWAY_SCALE="2.5"
