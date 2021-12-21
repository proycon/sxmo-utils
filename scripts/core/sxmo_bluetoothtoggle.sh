#!/bin/sh

# Must be run as root

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
	modprobe bluetooth
	modprobe hci_uart
	modprobe btrtl
	modprobe btbcm
	modprobe bnep
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
	rmmod hci_uart
	rmmod btbcm
	rmmod btrtl
	rmmod bnep
	rmmod bluetooth
}

case "$1" in
	on)
		on
		;;
	off)
		off
		;;
	*) #toggle
		if rfkill -rn | grep bluetooth | grep -qE "unblocked unblocked"; then
			off
		else
			on
		fi
esac

sxmo_statusbarupdate.sh
