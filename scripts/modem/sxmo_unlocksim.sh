#!/bin/sh

# small utility to prompt user for PIN and unlock mode

# shellcheck source=scripts/core/sxmo_common.sh
. "$(which sxmo_common.sh)"
# shellcheck source=scripts/core/sxmo_icons.sh
. "$(which sxmo_icons.sh)"

set -e

# in dwm, close any dmenus.  We don't need to do this in sway.
[ "$SXMO_WM" = "dwm" ] && (sxmo_dmenu.sh close || true)

while : ; do
	PICKED="$(
		cat <<EOF | sxmo_dmenu_with_kb.sh -l 3 -c -p "PIN:"
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

