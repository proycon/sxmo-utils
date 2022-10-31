#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

pactl subscribe | while read -r line; do
	case "$line" in
		"Event 'change' on sink "*)
			sxmo_hook_statusbar.sh volume
			sxmo_audio.sh notify
			;;
		"Event 'change' on source "*)
			sxmo_hook_statusbar.sh volume
			sxmo_audio.sh micnotify
			;;
	esac
done
