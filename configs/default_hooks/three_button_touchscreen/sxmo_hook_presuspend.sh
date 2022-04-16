#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script is called prior to suspending

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

sxmo_daemons.sh stop periodic_blink

pkill clickclack
sxmo_keyboard.sh close
pkill mpv #if any audio/video is playing, kill it (it might stutter otherwise)

case "$SXMO_WM" in
	dwm)
		sxmo_dmenu.sh close
		;;
esac
