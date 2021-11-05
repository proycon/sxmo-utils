#!/bin/sh

# this script goal is to move the screen lock state from lock to off then crust

if [ "$1" = "--idle" ]; then
	sxmo_hooks.sh is_idle || exit
fi

initial_state="$(sxmo_screenlock.sh getCurState)"
case "$initial_state" in
	unlock)
		exit # We only manage locked target_state
		;;
	lock)
		target_state=off
		;;
	off)
		target_state=crust
		;;
esac

if [ "crust" = "$target_state" ] && ! sxmo_hooks.sh can_suspend; then
	exit
fi

sxmo_screenlock.sh "$target_state"
