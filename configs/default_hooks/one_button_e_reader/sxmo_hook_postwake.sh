#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

if [ -f /sys/power/wake_lock ]; then
	echo "stay_awake ${SXMO_UNLOCK_IDLE_TIME:-120}000000000" | doas tee -a /sys/power/wake_lock > /dev/null
fi

# Add here whatever you want to do
