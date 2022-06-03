#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

printf "Sxmo "
cat "$(xdg_data_path sxmo/version)"
case "$SXMO_WM" in
	dwm)
		/usr/bin/dwm -v
		/usr/bin/dmenu -v
		/usr/bin/st -v
		;;
	sway)
		/usr/bin/sway -v
		/usr/bin/bemenu -v
		/usr/bin/foot -v
		;;
esac

"$KEYBOARD" -v
/usr/bin/mmcli --version | head -n 1
. /etc/os-release
printf "%s %s" "$NAME" "$VERSION"

if [ "$1" = "--block" ]; then
	printf " (press return to exit)"
	read -r
fi
