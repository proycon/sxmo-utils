#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

not_ready_yet() {
	sxmo_notify_user.sh "Your device looks not ready yet"
	exit 1
}

case "$(realpath /var/lib/tinydm/default-session.desktop)" in
	*"swmo.desktop")
		command -v dwm >/dev/null || not_ready_yet
		doas tinydm-set-session -f -s "$(xdg_data_path xsessions/sxmo.desktop)" || not_ready_yet
		pkill sway
		;;
	*"sxmo.desktop")
		command -v sway >/dev/null || not_ready_yet
		doas tinydm-set-session -f -s "$(xdg_data_path wayland-sessions/swmo.desktop)" || not_ready_yet
		pkill dwm
		;;
esac
