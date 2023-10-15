#!/bin/sh
# Pine Note!
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# from https://github.com/DorianRudolph/pinenotes
export WLR_RENDERER_ALLOW_SOFTWARE=1 # Dorian
export GALLIUM_DRIVER=llvmpipe # Dorian
export LIBGL_ALWAYS_SOFTWARE=true

export SXMO_TOUCHSCREEN_ID="10"
export SXMO_STYLUS_ID="12"
export SXMO_DISABLE_LEDS="1"
export SXMO_MIN_BRIGHTNESS="0" # we can set brightness all the way down
export SXMO_BMENU_LANDSCAPE_LINES="15"
export SXMO_MONITOR="Unknown-1"
export SXMO_POWER_BUTTON="0:0:rk805_pwrkey"
export SXMO_ROTATION_POLL_TIME="0" # the device already polls at 1s so a further 1s poll is pointless
export SXMO_UNLOCK_IDLE_TIME="30"
export SXMO_SPEAKER="Master"
export SXMO_SWAY_SCALE="2"
export SXMO_STATES="unlock"
export SXMO_SUSPENDABLE_STATES="unlock 120"
export SXMO_NO_MODEM=1
