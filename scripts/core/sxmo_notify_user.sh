#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

notify-send "$@"

while [ "$#" -gt 0 ]; do
	case "$1" in
		--urgency=*)
			shift
			;;
		*)
			printf "%s\n" "$1" >&2
			shift
			;;
	esac
done
