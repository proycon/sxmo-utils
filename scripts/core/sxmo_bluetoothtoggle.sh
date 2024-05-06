#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# Must be run as root

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

on() {
	rfkill unblock bluetooth
	case "$SXMO_OS" in
		alpine|postmarketos)
			rc-service bluetooth start
			rc-update add bluetooth
			;;
		arch|archarm|nixos|debian)
			systemctl start bluetooth
			systemctl enable bluetooth
			;;
	esac
}

off() {
	case "$SXMO_OS" in
		alpine|postmarketos)
			rc-service bluetooth stop
			rc-update del bluetooth
			;;
		arch|archarm|nixos|debian)
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
		if rfkill list bluetooth -no ID,SOFT,HARD | grep -vq " blocked"; then
			off
		else
			on
		fi
esac
