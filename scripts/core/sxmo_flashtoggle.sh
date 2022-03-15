#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

if sxmo_led.sh get white | grep -vq ^100$; then
	sxmo_led.sh set white 100
else
	sxmo_led.sh set white 0
fi
