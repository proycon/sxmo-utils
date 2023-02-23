#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

if ! command -v mnc > /dev/null; then
	exit 0
fi

crontab -l | grep sxmo_rtcwake | mnc


