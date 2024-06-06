#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

printf "Sxmo "
cat "$(xdg_data_path sxmo/version)"
case "$SXMO_WM" in
	dwm)
		/usr/bin/dwm -v
		/usr/bin/dmenu -v
		/usr/bin/st -v
		if ! command -v bonsaictl > /dev/null; then
			echo "no bonsai"
		else
			which bonsaictl
		fi
		;;
	sway)
		/usr/bin/sway -v
		/usr/bin/bemenu -v
		/usr/bin/foot -v
		if ! command -v bonsaictl > /dev/null; then
			echo "no bonsai"
		else
			which bonsaictl
		fi
		;;
esac

printf "superd "
/usr/bin/superctl --version
pactl info
"$KEYBOARD" -v
/usr/bin/mmcli --version | head -n 1
uname -m
. /etc/os-release
printf "%s %s\n" "$NAME" "$VERSION"

# shellcheck disable=SC2034
if [ "$1" = "--block" ]; then
	printf " (press return to exit)"
	read -r _
fi
