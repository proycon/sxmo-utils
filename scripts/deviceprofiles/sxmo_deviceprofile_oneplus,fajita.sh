#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

export SXMO_DISABLE_LEDS="1"
export SXMO_VOLUME_BUTTON="1:1:Volume_keys"
export SXMO_POWER_BUTTON="0:0:pm8941_pwrkey"
# TODO: change to output display
export SXMO_MONITOR="1739:0:Synaptics_S3706B"
export SXMO_VIBRATE_DEV="/dev/input/by-path/platform-c440000.spmi-platform-c440000.spmi:pmic@3:haptics@c000-event"
export SXMO_SWAY_SCALE="2"
