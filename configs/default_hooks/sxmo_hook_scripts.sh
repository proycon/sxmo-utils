#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script will output the content of the scripts menu

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh
# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh

write_line() {
	printf "%s ^ 0 ^ %s\n" "$1" "$2"
}

get_title() {
	title=""
	eval "$(head "$1" | grep '# title="[^\\"]*"' | sed 's/^# //g')"
	if [ -n "$title" ]; then
		echo "$title"
	else
		basename="$(basename "$1")"
		echo "$icon_itm $basename"
	fi
}

if [ -f "$XDG_CONFIG_HOME/sxmo/userscripts" ]; then
	cat "$XDG_CONFIG_HOME/sxmo/userscripts"
elif [ -d "$XDG_CONFIG_HOME/sxmo/userscripts" ]; then
	find -L "$XDG_CONFIG_HOME/sxmo/userscripts" -type f -o -type l | sort -f | while read -r script; do
		title="$(get_title "$script")"
		write_line "$title" "$script"
	done
fi

write_line "$icon_cfg Edit Userscripts" "sxmo_terminal.sh $EDITOR $XDG_CONFIG_HOME/sxmo/userscripts/*"

# System Scripts
find "$(xdg_data_path sxmo/appscripts)" -type f -o -type l | sort -f | while read -r script; do
	title="$(get_title "$script")"
	write_line "$title" "$script"
done
