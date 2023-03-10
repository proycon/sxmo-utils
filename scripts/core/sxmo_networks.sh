#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

set -e

VPNDEVICE="$(nmcli con show --active | grep -E 'wireguard|vpn' | awk '{ print $1 }')"

nofail() {
	"$@" || return 0
}

stderr() {
	sxmo_log "$*"
}

menu() {
	dmenu -i "$@"
}

connections() {
	nmcli -c no -f device,type,name -t c show | \
		sed "s/802-11-wireless:/$icon_wif /" | \
		sed "s/gsm:/$icon_mod /" | \
		sed "s/vpn*:/$icon_key /" |\
		sed "s/wireguard*:/$icon_key /" |\
		sed "s/802-3-ethernet:/$icon_usb /" | \
		sed "s/^:/$icon_dof /" |\
		sed "s/^cdc-wdm.*:/$icon_don /" |\
		sed "s/^$VPNDEVICE.*:/$icon_don /" |\
		sed "s/^wlan.*:/$icon_don /" |\
		sed "s/^wwan.*:/$icon_don /" |\
		sed "s/^eth.*:/$icon_don /" |\
		sed "s/^usb.*:/$icon_don /"
}

toggleconnection() {
	CONNLINE="$1"
	if echo "$CONNLINE" | grep -q "^$icon_don "; then
		CONNNAME="$(echo "$CONNLINE" | cut -d' ' -f3-)"
		RES="$(nofail nmcli c down "$CONNNAME" 2>&1)"
	else
		CONNNAME="$(echo "$CONNLINE" | cut -d' ' -f3-)"
		rfkill list wifi | grep -q "yes" || WIFI_ENABLED=1
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
			menu -p "Delete Network"
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
	[ -z "$CONNNAME" ] && return
	echo "$CONNNAME" | grep -q "Close Menu" && return

	APN="$(
		echo "$icon_cls Close Menu" |
			sxmo_dmenu_with_kb.sh -p "APN"
	)"
	[ -z "$APN" ] && return
	echo "$APN" | grep -q "Close Menu" && return

	USERNAME="$(printf "None\n%s Close Menu\n" "$icon_cls" | menu -p "Username")"
	case "$USERNAME" in
		""|"$icon_cls Close Menu")
			return
			;;
		None)
			unset USERNAME
			;;
	esac

	PASSWORD="$(printf "None\n%s Close Menu\n" "$icon_cls" | menu -p "Password")"
	case "$PASSWORD" in
		""|"$icon_cls Close Menu")
			return
			;;
		None)
			unset PASSWORD
			;;
	esac

	RES="$(nofail nmcli c add \
		type gsm \
		ifname "$(getifname gsm)" \
		con-name "$CONNNAME" \
		apn "$APN" \
		${PASSWORD:+gsm.password "$PASSWORD"} \
		${USERNAME:+gsm.username "$USERNAME"} \
		2>&1)"
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
	if [ -z "$PASSPHRASE" ]; then
		unset PASSPHRASE
	fi
	echo "$PASSPHRASE" | grep -q "Close Menu" && return

	RES="$(nofail nmcli c add \
		type wifi \
		ifname wlan0 \
		con-name "$SSID" \
		ssid "$SSID" \
		${PASSPHRASE:+802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk "$PASSPHRASE"} 2>&1)"
	stderr "$RES"
	notify-send "$RES"
}

addhotspotusbmenu() {
	CONNNAME="$(
		echo "$icon_cls Close Menu" |
			sxmo_dmenu_with_kb.sh -p "Alias"
	)"
	[ -z "$CONNNAME" ] && return
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

	# valid keys for WPA networks have a lengths of 8-63 characters
	keylen=$( echo "$key" | tr -d '\n' | wc -c )
	keylen=$(( keylen ))
	if [ $keylen -lt 8 ]; then
		notify-send "key too short ($keylen < 8)"
		stderr "key too short ($keylen < 8)"
		return
	elif [ $keylen -gt 63 ]; then
		notify-send "key too long ($keylen > 63)"
		stderr "key too long ($keylen > 63)"
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
		CHOICE="$(
			rfkill list wifi | grep -q "yes" || WIFI_ENABLED=1

			grep . << EOF | sxmo_dmenu.sh -p "Networks"
$icon_cls Close Menu
$(
	if [ -z "$WIFI_ENABLED" ]; then
		connections | grep -v "$icon_wif"
	else
		connections
	fi
)
$icon_mod Add a GSM Network
$([ -z "$WIFI_ENABLED" ] || printf "%s Add a WPA Network\n" "$icon_wif")
$([ -z "$WIFI_ENABLED" ] || printf "%s Add a Wifi Hotspot\n" "$icon_wif")
$icon_usb Add a USB Hotspot
$icon_cls Delete a Network
$(
	if [ -z "$WIFI_ENABLED" ]; then
		printf "%s Enable Wifi\n" "$icon_wif"
	else
		printf "%s Disable Wifi\n" "$icon_wif"
	fi
)
$icon_cfg Nmtui
$icon_cfg Ifconfig
$([ -z "$WIFI_ENABLED" ] || printf "%s Scan Wifi Networks\n" "$icon_wif")
EOF
		)" || exit

		case "$CHOICE" in
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
			*"Disable Wifi"|*"Enable Wifi" )
				doas sxmo_wifitoggle.sh
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
