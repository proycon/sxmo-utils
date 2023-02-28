#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This hook displays the sms log for a numbers passed as $1

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

NUMBER="$1"
TERMNAME="$NUMBER SMS"
export TERMNAME

# If it's already open, switch to it.
if [ "$SXMO_WM" = "sway" ] && [ -z "$SSH_CLIENT" ]; then
	regesc_termname="$(echo "$TERMNAME" | sed 's|+|\\+|g')"
	swaymsg "[title=\"^$regesc_termname\$\"]" focus && exit 0
fi
sxmo_terminal.sh sh -c "tail -n9999 -f \"$SXMO_LOGDIR/$NUMBER/sms.txt\""
