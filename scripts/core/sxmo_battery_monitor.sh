#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

upower -m | while read -r line; do
	# swallow first line
	if [ -z "$last_line" ]; then
		last_line=1
		continue
	fi
	if [ "$last_line" = "$line" ]; then
		continue
	fi
	last_line="$line"

	#time="$(printf %s "$line" | cut -d"	" -f1)"
	line="$(printf %s "$line" | cut -d"	" -f2)"
	event="$(printf %s "$line" | cut -d":" -f1)"
	object="$(printf %s "$line" | cut -d":" -f2 | sed 's|^\( *\)||')"

	if [ -z "$object" ]; then
		continue
	fi

	set -- sxmo_hook_battery.sh "$object" "$event"

	sxmo_debug "$*"
	"$@"
done
