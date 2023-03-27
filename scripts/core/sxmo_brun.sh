#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

case "$SXMO_WM" in
	dwm)
		exec dmenu_run "$@"
		;;
	sway)
		exec bemenu-run "$@"
		;;
esac
