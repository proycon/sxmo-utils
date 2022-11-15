#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

. sxmo_common.sh

notify-send "$@"

while [ "$#" -gt 0 ]; do
	case "$1" in
		--urgency=*)
			shift
			;;
		*)
			sxmo_log "$1"
			shift
			;;
	esac
done
