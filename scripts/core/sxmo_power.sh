#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

usage() {
	printf "usage: %s [reboot|poweroff]\n" "$(basename "$0")"
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
	*)
		usage
		exit 1
		;;
esac
