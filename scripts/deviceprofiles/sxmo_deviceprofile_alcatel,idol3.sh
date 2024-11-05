#!/bin/sh
# Alcatel OneTouch Idol 3 (5.5) (6045Y)
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2024 Sxmo Contributors

export SXMO_VIBRATE_DEV="/dev/input/by-path/platform-200f000.spmi-platform-200f000.spmi:pmic@1:vibrator@c000-event"
export SXMO_MIN_BRIGHTNESS=1 # Still visible
export SXMO_VIBRATE_STRENGTH=256 # Is activated between 256 and 65535, from lowest to highest
