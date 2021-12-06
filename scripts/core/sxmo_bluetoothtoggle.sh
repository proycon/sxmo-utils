#!/usr/bin/env sh

# Must be run as root

if [ -f /etc/os-release ]; then
	. /etc/os-release
	OS="$NAME"
else
	OS="Unknown"
fi

on() {
	modprobe bluetooth
	modprobe hci_uart
	modprobe btrtl
	modprobe btbcm
	modprobe bnep
	rfkill unblock bluetooth
	case "$OS" in
		"Alpine Linux"|postmarketOS)
			rc-service bluetooth start
			;;
		"Arch Linux ARM"|alarm)
			systemctl stop bluetooth
			;;
	esac
}

off() {
	case "$OS" in
		"Alpine Linux"|postmarketOS)
			rc-service bluetooth stop
			;;
		"Arch Linux ARM"|alarm)
			systemctl stop bluetooth
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
