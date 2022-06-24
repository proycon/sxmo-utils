#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

WINNAME="$1"
CHOICE="$2"

sxmo_log "Unknown choice <$CHOICE> selected from contextmenu <$WINNAME>"
