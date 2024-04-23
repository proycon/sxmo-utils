#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2024 Sxmo Contributors

if [ "$(brightnessctl -d "white:flash" get)" -gt 0 ]; then
	brightnessctl -q -d "white:flash" set "0%"
else
	brightnessctl -q -d "white:flash" set "100%"
fi
