#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

export WLR_RENDERER=pixman
export SXMO_DISABLE_LEDS=1
export SXMO_SWAY_SCALE="2.5"
export SXMO_POWER_BUTTON="1:1:gpio-keys"
export SXMO_STATES="unlock"
export SXMO_SUSPENDABLE_STATES="unlock 120"
export SXMO_ROTATE_DIRECTION="left"
export SXMO_ROTATE_START=1
export SXMO_MIN_BRIGHTNESS=0 # to disable all backlight
export SXMO_NO_MODEM=1
