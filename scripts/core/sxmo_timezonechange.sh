#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

change_alpine() {
	echo "Changing timezone to $1"

	doas setup-timezone -z "$1"
	sxmo_hook_statusbar.sh time

	echo "Timezone changed ok"
}

change_arch() {
	echo "Changing timezone to $1"

	timedatectl set-timezone "$1"
	sxmo_hook_statusbar.sh time

	echo "Timezone changed ok"
}

menu() {
	T="$(
		find /usr/share/zoneinfo -type f |
		sed  's#^/usr/share/zoneinfo/##g' |
		sort |
		sxmo_dmenu_with_kb.sh -p Timezone -i
	)" || exit 0
	sxmo_terminal.sh "$0" "$T"
}

if [ $# -gt 0 ]; then
	trap "read -r" EXIT
	set -e

	case "$OS" in
		alpine|postmarketos) change_alpine "$@";;
		arch|archarm) change_arch "$@";;
		*) echo "Changing the timezone isn't implemented on your distro yet";;
	esac
else
	menu
fi
