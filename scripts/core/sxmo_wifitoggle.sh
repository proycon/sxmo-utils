#!/bin/sh

# Note: this script should be run as root via doas

on() {
	rfkill unblock wlan
}

off() {
	rfkill block wlan
}

case "$1" in
	on)
		on
		;;
	off)
		off
		;;
	*) #toggle
		if rfkill -rn | grep wlan | grep -qE "unblocked unblocked"; then
			off
		else
			on
		fi
esac
