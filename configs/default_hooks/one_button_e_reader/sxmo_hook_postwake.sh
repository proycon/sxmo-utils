#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

sxmo_wakelock.sh lock stay_awake "${SXMO_UNLOCK_IDLE_TIME:-120}s"

# Add here whatever you want to do
