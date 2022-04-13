#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

usage() {
	printf "usage: %s [reboot|poweroff]\n" "$(basename "$0")"
}

case "$1" in
	reboot)
		sxmo_hook_reboot.sh
		sxmo_daemons.sh stop all #  TODO: If I manage to remove all sxmo_daemons.sh calls. Remove this
		pkill superd
		doas reboot
		;;
	poweroff)
		sxmo_hook_poweroff.sh
		sxmo_daemons.sh stop all  # TODO: If I manage to remove all sxmo_daemons.sh calls. Remove this
		pkill superd
		doas poweroff
		;;
	*)
		usage
		exit 1
		;;
esac
