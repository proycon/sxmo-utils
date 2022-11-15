#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

if ! command -v mnc > /dev/null; then
	exit 1
fi

crontab -l | grep sxmo_rtcwake | mnc
