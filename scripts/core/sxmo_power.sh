#!/bin/sh

usage() {
	printf "usage: %s [reboot|poweroff]\n" "$(basename "$0")"
}

case "$1" in
	reboot)
		sxmo_hooks.sh reboot
		sxmo_daemons.sh stop all
		doas reboot
		;;
	poweroff)
		sxmo_hooks.sh poweroff
		sxmo_daemons.sh stop all
		doas poweroff
		;;
	*)
		usage
		exit 1
		;;
esac
