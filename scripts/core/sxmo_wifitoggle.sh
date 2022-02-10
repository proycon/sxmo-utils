#!/bin/sh

# Note: this script should be run as root via doas

# shellcheck source=scripts/core/sxmo_common.sh
. "$(which sxmo_common.sh)"

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
		if rfkill list wifi | grep -q "yes"; then
			on
		else
			off
		fi
esac
