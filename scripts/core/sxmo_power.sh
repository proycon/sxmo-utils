#!/bin/sh

usage() {
	printf "usage: %s [reboot|poweroff]\n" "$(basename "$0")"
}

case "$1" in
	reboot)
		pkill -f sxmo_lock_idle.sh
		sxmo_hooks.sh reboot
		doas reboot
		;;
	poweroff)
		pkill -f sxmo_lock_idle.sh
		sxmo_hooks.sh poweroff
		doas poweroff
		;;
	*)
		usage
		exit 1
		;;
esac
