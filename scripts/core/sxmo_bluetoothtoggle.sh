#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# Must be run as root

# shellcheck source=scripts/core/sxmo_common.sh
. "$(which sxmo_common.sh)"

# see sxmo_common.sh
if [ -e /etc/os-release ]; then
	# shellcheck source=/dev/null
	. /etc/os-release
elif [ -e /usr/lib/os-release ]; then
	# shellcheck source=/dev/null
	. /usr/lib/os-release
fi
export OS="${ID:-unknown}"

on() {
	rfkill unblock bluetooth
	case "$OS" in
		alpine|postmarketos)
			rc-service bluetooth start
			rc-update add bluetooth
			;;
		arch|archarm)
			systemctl start bluetooth
			systemctl enable bluetooth
			;;
	esac
}

off() {
	case "$OS" in
		alpine|postmarketos)
			rc-service bluetooth stop
			rc-update del bluetooth
			;;
		arch|archarm)
			systemctl stop bluetooth
			systemctl disable bluetooth
			;;
	esac
	rfkill block bluetooth
}

case "$1" in
	on)
		on
		;;
	off)
		off
		;;
	*) #toggle
		if rfkill list bluetooth | grep -q "yes"; then
			on
		else
			off
		fi
esac
