#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# small utility to prompt user for PIN and unlock mode

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh
# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh

set -e

# in dwm, close any dmenus.  We don't need to do this in sway.
[ "$SXMO_WM" = "dwm" ] && (sxmo_dmenu.sh close || true)

case "$SXMO_MENU" in
	bemenu)
		MENU_OPTS="-l 3"
		;;
	wofi)
		MENU_OPTS="-L 3"
		;;
	dmenu)
		MENU_OPTS="-l 3"
		;;
esac

while : ; do
	# shellcheck disable=SC2086
	#  (MENU_OPTS is not quoted because we want to split args here)
	PICKED="$(
		cat <<EOF | sxmo_dmenu.sh $MENU_OPTS -p "PIN:"
$icon_cls Cancel
0000
1234
EOF
	)"
	case "$PICKED" in
		"$icon_cls Cancel"|"")
			exit
			;;
		*)
			SIM="$(mmcli -m any | grep -oE 'SIM\/([0-9]+)' | cut -d'/' -f2 | head -n1)"
			MSG="$(mmcli -i "$SIM" --pin "$PICKED" 2>&1 || true)"
			[ -n "$MSG" ] && sxmo_notify_user.sh "$MSG"
			if printf "%s\n" "$MSG" | grep -q "not SIM-PIN locked"; then
				exit
			fi
			if printf "%s\n" "$MSG" | grep -q "successfully sent PIN code to the SIM"; then
				exit
			fi
			;;
	esac
done

