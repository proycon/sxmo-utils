#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2024 Sxmo Contributors

# Tabbed options for various programs

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

OPTIONS="
alacritty --embed
st -w
surf -e
zathura -e
"

LIST="$(grep . <<-EOF | sxmo_dmenu.sh -p "Tabbed Embed"
	$OPTIONS
	Nothing
	Close
EOF
)"

case "$LIST" in
	"Close"|"") exit 0 ;;
	"Nothing") tabbed ;;
	*)
		# shellcheck disable=SC2086
		tabbed $LIST
	;;
esac
