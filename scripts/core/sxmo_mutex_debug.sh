#! /bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

sxmo_mutex.sh can_suspend list

tail -f "$XDG_STATE_HOME"/sxmo.log | stdbuf -oL grep 'sxmo_mutex.sh'
