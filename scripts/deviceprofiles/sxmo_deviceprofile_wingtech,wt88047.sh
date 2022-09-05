#!/bin/sh
# xiaomi redmi 2
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

export SXMO_DISABLE_LEDS="1"
export SXMO_MONITOR="0:0:generic_ft5x06_(8d)"
export SXMO_POWER_BUTTON="0:0:pm8941_pwrkey"
export SXMO_VOLUME_BUTTON="1:1:GPIO_Buttons 0:0:pm8941_resin"
