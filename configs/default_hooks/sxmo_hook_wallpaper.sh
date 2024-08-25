#!/bin/sh -e
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

# This script is executed once, and must output the wallpaper to display

installed_wallpapers() {
	xdg_data_path wallpapers 0 "\0" | xargs -r0I{} find "{}" -name "$SXMO_OS.*"
}

sxmo_wallpaper() {
	xdg_data_path sxmo/background.jpg
}

all_wallpapers() {
	installed_wallpapers
	sxmo_wallpaper
}

if [ -n "$SXMO_BG_IMG" ]; then
	printf "%s" "$SXMO_BG_IMG"
	exit
fi

all_wallpapers | head -n1
