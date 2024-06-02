#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=configs/profile.d/sxmo_init.sh
. /etc/profile.d/sxmo_init.sh

. sxmo_common.sh

sxmo_wakelock.sh unlock sxmo_waiting_cronjob

sxmo_log "Running $*"
exec "$@"
