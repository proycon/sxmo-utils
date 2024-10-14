#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

case "$SXMO_MENU" in
	dmenu)
		exec dmenu_run "$@"
		;;
	bmenu)
		exec bemenu-run "$@"
		;;
	wofi)
		exec wofi -O alphabetical -i --show run "$@"
		;;
esac
