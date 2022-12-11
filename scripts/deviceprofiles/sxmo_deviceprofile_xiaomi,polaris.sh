#!/bin/sh
# mi mix 2s
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

export SXMO_DISABLE_LEDS="1"
# TODO: change to output display
export SXMO_MONITOR="1739:0:Synaptics_S3330"
export SXMO_POWER_BUTTON="0:0:pm8941_pwrkey"
export SXMO_VOLUME_BUTTON="1:1:gpio-keys 0:0:pm8941_resin"
export SXMO_SWAY_SCALE="2"
