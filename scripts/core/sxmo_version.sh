#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

printf "Sxmo "
cat /usr/share/sxmo/version
case "$(sxmo_wm.sh)" in
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
