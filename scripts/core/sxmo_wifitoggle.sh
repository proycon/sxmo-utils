#!/bin/sh

# Note: this script should be run as root via doas

[ -n "$WLAN_MODULE" ] || WLAN_MODULE="8723cs"

on() {
	if lsmod | grep -qE "$WLAN_MODULE"; then
		rfkill unblock wlan
	else
		modprobe "$WLAN_MODULE" && rfkill unblock wlan
	fi
}

off() {
	if lsmod | grep -qE "$WLAN_MODULE"; then
		rfkill block wlan && rmmod "$WLAN_MODULE"
	else
		rfkill block wlan
	fi
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

sxmo_statusbarupdate.sh wifitoggle
