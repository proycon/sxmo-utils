#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

case "$SXMO_WM" in
	sway) swaymsg kill;;
	dwm) xdotool windowkill "$(xdotool getactivewindow)";;
esac
