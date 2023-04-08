#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

usage() {
	printf "usage: %s [reboot|poweroff|logout|togglewm]\n" "$(basename "$0")"
}

case "$1" in
	reboot)
		sxmo_hook_reboot.sh
		sxmo_daemons.sh stop all
		doas reboot
		;;
	poweroff)
		sxmo_hook_poweroff.sh
		sxmo_daemons.sh stop all
		doas poweroff
		;;
	logout)
		sxmo_hook_logout.sh
		case "$SXMO_WM" in
			"sway") swaymsg exit ;;
			"dwm") pkill dwm ;;
		esac
		;;
	togglewm)
		case "$(realpath /var/lib/tinydm/default-session.desktop)" in
			*"swmo.desktop")
				if command -v dwm > /dev/null; then
					if doas tinydm-set-session -f -s "$(xdg_data_path xsessions/sxmo.desktop)"; then
						sxmo_hook_logout.sh
						swaymsg exit
					else
						sxmo_notify_user.sh "You do not have tinydm installed."
					fi
				else
					sxmo_notify_user.sh "You do not have dwm installed."
				fi
				;;
			*"sxmo.desktop")
				if command -v sway >/dev/null; then
					if doas tinydm-set-session -f -s "$(xdg_data_path wayland-sessions/swmo.desktop)"; then
						sxmo_hook_logout.sh
						pkill dwm
					else
						sxmo_notify_user.sh "You do not have tinydm installed."
					fi
				else
					sxmo_notify_user.sh "You do not have sway installed."
				fi
				;;
		esac
		;;
	*)
		usage
		exit 1
		;;
esac
