#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

sxmo_terminal.sh sh -c "tail -n9999 -f $SXMO_LOGDIR/modemlog.tsv"
