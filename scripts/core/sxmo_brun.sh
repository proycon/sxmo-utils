#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh


if [ -z "$SXMO_MENU" ]; then
	case "$SXMO_WM" in
		sway)
			SXMO_MENU=bemenu
			;;
		dwm)
			SXMO_MENU=dmenu
			;;
	esac
fi


case "$SXMO_MENU" in
	dmenu)
		exec dmenu_run "$@"
		;;
	bemenu)
		exec bemenu-run "$@"
		;;
	wofi)
		exec wofi -O alphabetical -i --show run "$@"
		;;
esac
