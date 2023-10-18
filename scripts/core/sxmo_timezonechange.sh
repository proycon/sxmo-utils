#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

change_alpine() {
	echo "Changing timezone to $1"

	doas setup-timezone -z "$1"
	sxmo_hook_statusbar.sh time

	echo "Timezone changed ok"
}

change_systemd() {
	echo "Changing timezone to $1"

	timedatectl set-timezone "$1"
	sxmo_hook_statusbar.sh time

	echo "Timezone changed ok"
}

menu() {
	zoneinfo_dir=$(xdg_data_path zoneinfo)
	T="$(
		find "$zoneinfo_dir" -type f |
		sed  "s#^${zoneinfo_dir}/##g" |
		sort |
		sxmo_dmenu.sh -p Timezone -i
	)" || exit 0
	sxmo_terminal.sh "$0" "$T"
}

if [ $# -gt 0 ]; then
	trap "read -r" EXIT
	set -e

	case "$SXMO_OS" in
		alpine|postmarketos) change_alpine "$@";;
		arch|archarm|debian) change_systemd "$@";;
		nixos) echo "Change the timezone in configuration.nix with time.timeZone = \"[timezone]\"";;
		*) echo "Changing the timezone isn't implemented on your distro yet";;
	esac
else
	menu
fi
