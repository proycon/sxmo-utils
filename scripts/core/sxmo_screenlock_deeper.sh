#!/bin/sh

# this script goal is to move the screen lock state from lock to off then crust

state="$(sxmo_screenlock.sh getCurState)"
case "$state" in
	unlock)
		exit # We only manage locked state
		;;
	lock)
		state=off
		;;
	off)
		state=crust
		;;
esac

sxmo_screenlock.sh "$state"
