#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

set -e

nofail() {
	"$@" || return 0
}

stderr() {
	printf "%s sxmo_networks.sh: %s.\n" "$(date)" "$*" >&2
}

connections() {
	nmcli -c no -f device,type,name -t c show | \
		sed "s/802-11-wireless:/$icon_wif /" | \
		sed "s/gsm:/$icon_mod /" | \
		sed "s/802-3-ethernet:/$icon_usb /" | \
		sed "s/^:/$icon_dof /" |\
		sed "s/^cdc-wdm.*:/$icon_don /" |\
		sed "s/^wlan.*:/$icon_don /" |\
		sed "s/^usb.*:/$icon_don /"
}

toggleconnection() {
	CONNLINE="$1"
	if echo "$CONNLINE" | grep -q "^$icon_don "; then
		CONNNAME="$(echo "$CONNLINE" | cut -d' ' -f3-)"
		RES="$(nofail nmcli c down "$CONNNAME" 2>&1)"
	else
		CONNNAME="$(echo "$CONNLINE" | cut -d' ' -f3-)"
		if [ "$(echo "$CONNLINE" | cut -d' ' -f2)" = "$icon_wif" ] && [ -z "$WIFI_ENABLED" ]; then
			notify-send "Enabling wifi first."
			doas sxmo_wifitoggle.sh
		fi
		RES="$(nofail nmcli c up "$CONNNAME" 2>&1)"
	fi
	notify-send "$RES"
	stderr "$RES"
}

deletenetworkmenu() {
	CHOICE="$(
		printf %b "$icon_cls Close Menu\n$(connections)" |
			dmenu -p "Delete Network"
	)"
	[ -z "$CHOICE" ] && return
	echo "$CHOICE" | grep -q "Close Menu" && return
	CONNNAME="$(echo "$CHOICE" | cut -d' ' -f3-)"
	RES="$(nofail nmcli c delete "$CONNNAME" 2>&1)"
	notify-send "$RES"
	stderr "$RES"
}

getifname() {
	IFTYPE="$1"
	IFNAME="$(nmcli d | grep -m 1 "$IFTYPE" | cut -d' ' -f1)"
	if [ -z "$IFNAME" ]; then
		notify-send "No interface with type $IFTYPE found"
		stderr "No interface with type $IFTYPE found"
		IFNAME=lo
	fi
	echo "$IFNAME"
}

addnetworkgsmmenu() {
	CONNNAME="$(
		echo "$icon_cls Close Menu" |
			sxmo_dmenu_with_kb.sh -p "Alias"
	)"
	[ -z "$CONNAME" ] && return
	echo "$CONNNAME" | grep -q "Close Menu" && return

	APN="$(
		echo "$icon_cls Close Menu" |
			sxmo_dmenu_with_kb.sh -p "APN"
	)"
	[ -z "$APN" ] && return
	echo "$APN" | grep -q "Close Menu" && return

	# TODO: Support gsm bearer username & password
	RES="$(nofail nmcli c add \
		type gsm \
		ifname "$(getifname gsm)" \
		con-name "$CONNNAME" \
		apn "$APN" 2>&1)"
	stderr "$RES"
	notify-send "$RES"
}

addnetworkwpamenu() {
	SSID="$(
		nmcli d wifi list | tail -n +2 | grep -v '^\*' | awk -F'  ' '{ print $6 }' | grep -v '\-\-' |
		xargs -0 printf "$icon_cls Close Menu\n%s" |
		sxmo_dmenu_with_kb.sh -p "SSID"
	)"
	[ -z "$SSID" ] && return
	echo "$SSID" | grep -q "Close Menu" && return

	PASSPHRASE="$(
		echo "$icon_cls Close Menu" |
			sxmo_dmenu_with_kb.sh -p "Passphrase"
	)"
	[ -z "$PASSPHRASE" ] && return
	echo "$PASSPHRASE" | grep -q "Close Menu" && return

	RES="$(nofail nmcli c add \
		type wifi \
		ifname wlan0 \
		con-name "$SSID" \
		802-11-wireless-security.key-mgmt wpa-psk \
		ssid "$SSID" \
		802-11-wireless-security.psk "$PASSPHRASE" 2>&1)"
	stderr "$RES"
	notify-send "$RES"
}

addhotspotusbmenu() {
	CONNNAME="$(
		echo "$icon_cls Close Menu" |
			sxmo_dmenu_with_kb.sh -p "Alias"
	)"
	[ -z "$CONNAME" ] && return
	echo "$CONNNAME" | grep -q "Close Menu" && return

	# TODO: restart udhcpd after disconnecting on postmarketOS
	RES="$(nofail nmcli c add \
		type ethernet \
		ifname usb0 \
		con-name "$CONNNAME" \
		ipv4.method shared 2>&1)"
	stderr "$RES"
	notify-send "$RES"
}

addhotspotwifimenu() {
	SSID="$(
		echo "$icon_cls Close Menu" |
			sxmo_dmenu_with_kb.sh -p "SSID"
	)"
	[ -z "$SSID" ] && return
	echo "$SSID" | grep -q "Close Menu" && return

	key="$(
		echo "$icon_cls Close Menu" |
			sxmo_dmenu_with_kb.sh -p "Passphrase"
	)"
	[ -z "$key" ] && return
	echo "$key" | grep -q "Close Menu" && return

	key1="$(
		echo "$icon_cls Close Menu" |
			sxmo_dmenu_with_kb.sh -p "Confirm"
	)"
	[ -z "$key1" ] && return
	echo "$key1" | grep -q "Close Menu" && return

	if [ "$key" != "$key1" ]; then
		notify-send "key mismatch"
		stderr "key mismatch"
		return
	fi

	channel="$(
		printf "%s Close Menu\n11\n" "$icon_cls" | sxmo_dmenu_with_kb.sh -p "Channel"
	)"
	[ -z "$channel" ] && return
	echo "$channel" | grep -q "Close Menu" && return

	RES="$(nofail nmcli device wifi hotspot ifname wlan0 \
		con-name "Hotspot $SSID" \
		ssid "$SSID" \
		channel "$channel" \
		band bg password "$key")"
	stderr "$RES"
	notify-send "$RES"
}

networksmenu() {
	while true; do
		if rfkill -rn | grep wlan | grep -qE "unblocked unblocked"; then
			WIFI_ENABLED=1
		fi
		CHOICE="$(
			printf %b "
				$(connections)
				$icon_mod Add a GSM Network
				$([ -z "$WIFI_ENABLED" ] || printf %b "$icon_wif Add a WPA Network")
				$([ -z "$WIFI_ENABLED" ] || printf %b "$icon_wif Add a Wifi Hotspot")
				$icon_usb Add a USB Hotspot
				$icon_cls Delete a Network
				$icon_cfg Nmtui
				$icon_cfg Ifconfig
				$([ -z "$WIFI_ENABLED" ] || printf %b "$icon_wif Scan Wifi Networks")
				$([ -z "$WIFI_ENABLED" ] || printf %b "$icon_wif Disable Wifi")
				$([ -z "$WIFI_ENABLED" ] && printf %b "$icon_wif Enable Wifi")
				$icon_mnu System Menu
				$icon_cls Close Menu
			" |
			awk '{$1=$1};1' | grep '\w' | dmenu -p 'Networks'
		)"
		[ -z "$CHOICE" ] && exit
		case "$CHOICE" in
			*"System Menu" )
				sxmo_appmenu.sh sys && exit
				;;
			*"Close Menu" )
				exit
				;;
			*"Add a GSM Network" )
				addnetworkgsmmenu
				;;
			*"Add a WPA Network" )
				addnetworkwpamenu
				;;
			*"Add a Wifi Hotspot" )
				addhotspotwifimenu
				;;
			*"Add a USB Hotspot")
				addhotspotusbmenu
				;;
			*"Delete a Network" )
				deletenetworkmenu
				;;
			*"Nmtui" )
				sxmo_terminal.sh nmtui || continue # Killeable
				;;
			*"Ifconfig" )
				sxmo_terminal.sh watch -n 2 ifconfig || continue # Killeable
				;;
			*"Scan Wifi Networks" )
				sxmo_terminal.sh watch -n 2 nmcli d wifi list || continue # Killeable
				;;
			*"Enable Wifi" )
				doas sxmo_wifitoggle.sh
				sxmo_statusbarupdate.sh wifitoggle
				;;
			*"Disable Wifi" )
				doas sxmo_wifitoggle.sh
				sxmo_statusbarupdate.sh wifitoggle
				;;
			*)
				toggleconnection "$CHOICE"
				;;
		esac
	done
}

if [ $# -gt 0 ]; then
	"$@"
else
	networksmenu
fi
