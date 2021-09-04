#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

connections() {
	ACTIVE="$(nmcli -c no -t c show --active | cut -d: -f1,3 | sed "s/$/ $icon_chk/")"
	INACTIVE="$(nmcli -c no -t c show | cut -d: -f1,3)"
	printf %b "$ACTIVE\n$INACTIVE" | sort -u -t: -k1,1
}

toggleconnection() {
	CONNLINE="$1"
	CONNNAME="$(echo "$CHOICE" | cut -d: -f1)"
	if echo "$CONNLINE" | grep "$icon_chk"; then
		RES="$(nmcli c down "$CONNNAME" 2>&1)"
	else
		RES="$(nmcli c up "$CONNNAME" 2>&1)"
	fi
	notify-send "$RES"
}

deletenetworkmenu() {
	CHOICE="$(
		printf %b "Close Menu\n$(connections)" |
			dmenu -p "Delete Network"
	)"
	if [ "$CHOICE" = "Close Menu" ]; then
		return
	else
		CONNNAME="$(echo "$CHOICE" | cut -d: -f1)"
		RES="$(nmcli c delete "$CONNNAME" 2>&1)"
		notify-send "$RES"
	fi
}

getifname() {
	IFTYPE="$1"
	IFNAME="$(nmcli d | grep -m 1 "$IFTYPE" | cut -d' ' -f1)"
	[ -z "$IFNAME" ] && notify-send "No interface with type $IFTYPE found" && IFNAME=lo
	echo "$IFNAME"
}

addnetworkgsmmenu() {
	CONNNAME="$(
		echo "Close Menu" |
			sxmo_dmenu_with_kb.sh -p "Add GSM: Alias"
	)"
	[ "$CONNNAME" = "Close Menu" ] && return

	APN="$(
		echo "Close Menu" |
			sxmo_dmenu_with_kb.sh -p "Add GSM: APN"
	)"
	[ "$APN" = "Close Menu" ] && return

	# TODO: Support gsm bearer username & password
	nmcli c add \
		type gsm \
		ifname "$(getifname gsm)" \
		con-name "$CONNNAME" \
		apn "$APN"
}

addnetworkwpamenu() {
	SSID="$(
		nmcli d wifi list | tail -n +2 | grep -v '^\*' | awk -F'  ' '{ print $6 }' | grep -v '\-\-' |
		xargs -0 printf 'Close Menu\n%s' |
		sxmo_dmenu_with_kb.sh -p "Add WPA: SSID"
	)"
	[ "$SSID" = "Close Menu" ] && return

	PASSPHRASE="$(
		echo "Close Menu" |
			sxmo_dmenu_with_kb.sh -p "Add WPA: Passphrase"
	)"
	[ "$PASSPHRASE" = "Close Menu" ] && return

	nmcli c add \
		type wifi \
		ifname wlan0 \
		con-name "$SSID" \
		802-11-wireless-security.key-mgmt wpa-psk \
		ssid "$SSID" \
		802-11-wireless-security.psk "$PASSPHRASE"
}

addhotspotusbmenu() {
	CONNNAME="$(
		echo "Close Menu" |
			sxmo_dmenu_with_kb.sh -p "Add USB Hotspot: Alias"
	)"
	[ "$CONNNAME" = "Close Menu" ] && return

	# TODO: restart udhcpd after disconnecting on postmarketOS
	nmcli c add \
		type ethernet \
		ifname usb0 \
		con-name "$CONNNAME" \
		ipv4.method shared
}

networksmenu() {
	while true; do
		CHOICE="$(
			printf %b "
				$(connections)
				Add a GSM Network
				Add a WPA Network
				Add a Hotspot
				Add a USB Hotspot
				Delete a Network
				Launch Nmtui
				Launch Ifconfig
				Scan Wifi Networks
				System Menu
				Close Menu
			" |
			awk '{$1=$1};1' | grep '\w' | dmenu -p 'Networks'
		)"
		case "$CHOICE" in
			"System Menu" )
				sxmo_appmenu.sh sys && exit
				;;
			"Close Menu" )
				exit
				;;
			"Add a GSM Network" )
				addnetworkgsmmenu
				;;
			"Add a WPA Network" )
				addnetworkwpamenu
				;;
			"Add a Hotspot" )
				sxmo_hotspot.sh
				;;
			"Add a USB Hotspot")
				addhotspotusbmenu
				;;
			"Delete a Network" )
				deletenetworkmenu
				;;
			"Launch Nmtui" )
				sxmo_terminal.sh nmtui &
				;;
			"Launch Ifconfig" )
				sxmo_terminal.sh watch -n 2 ifconfig &
				;;
			"Scan Wifi Networks" )
				sxmo_terminal.sh watch -n 2 nmcli d wifi list &
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
