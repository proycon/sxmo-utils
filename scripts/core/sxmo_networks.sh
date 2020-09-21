#!/usr/bin/env sh

connections() {
	ACTIVE="$(nmcli -c no -t c show --active | cut -d: -f1,3 | sed 's/$/ ✓/')"
	INACTIVE="$(nmcli -c no -t c show | cut -d: -f1,3)"
	printf %b "$ACTIVE\n$INACTIVE" | sort -u -t: -k1,1 
}

toggleconnection() {
	CONNLINE="$1"
	CONNNAME="$(echo "$CHOICE" | cut -d: -f1)"
	if echo "$CONNLINE" | grep "✓"; then
		RES="$(nmcli c down "$CONNNAME" 2>&1)"
	else
		RES="$(nmcli c up "$CONNNAME" 2>&1)"
	fi
	notify-send "$RES"
}

deletenetworkmenu() {
	CHOICE="$(
		printf %b "Close Menu\n$(connections)" |
			dmenu -c -p "Delete Network" -l 14 -fn "Terminus-20"
	)"
	if [ "$CHOICE" = "Close Menu" ]; then
		return
	else
		CONNNAME="$(echo "$CHOICE" | cut -d: -f1)"
		RES="$(nmcli c delete "$CONNNAME" 2>&1)"
		notify-send "$RES"
	fi
}

addnetworkgsmmenu() {
	CONNNAME="$(
		echo "Close Menu" |
			sxmo_dmenu_with_kb.sh -c -p "Add GSM: Alias" -fn "Terminus-20" -l 20
	)"
	[ "$CONNNAME" = "Close Menu" ] && return

	APN="$(
		echo "Close Menu" |
			sxmo_dmenu_with_kb.sh -c -p "Add GSM: APN" -fn "Terminus-20" -l 20
	)"
	[ "$APN" = "Close Menu" ] && return

	# TODO: Support gsm bearer username & password
	nmcli c add \
		type gsm \
		ifname cdc-wdm0 \
		con-name "$CONNNAME" \
		apn "$APN"
}

addnetworkwpamenu() {
	SSID="$(
		nmcli d wifi list | tail -n +2 | grep -v '^*' | awk '{ print $2 }' | grep -v '\-\-' |
		xargs -0 printf 'Close Menu\n%s' |
		sxmo_dmenu_with_kb.sh -c -p "Add WPA: SSID" -fn "Terminus-20" -l 20
	)"
	[ "$SSID" = "Close Menu" ] && return

	PASSPHRASE="$(
		echo "Close Menu" |
			sxmo_dmenu_with_kb.sh -c -p "Add WPA: Passpharse" -fn "Terminus-20" -l 20
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


networksmenu() {
	while true; do
		CHOICE="$(
			printf %b "	
				$(connections)
				Add a GSM Network
				Add a WPA Network
				Delete a Network
				Launch Nmtui
				Launch Ifconfig
				Scan Wifi Networks
				Close Menu
			" | 
			awk '{$1=$1};1' | grep '\w' | dmenu -c -p 'Networks' -l 14 -fn 'Terminus-20'
		)"
		if [ "$CHOICE" = "Close Menu" ]; then
			exit
		elif [ "$CHOICE" = "Add a GSM Network" ]; then
			addnetworkgsmmenu
		elif [ "$CHOICE" = "Add a WPA Network" ]; then
		  addnetworkwpamenu
		elif [ "$CHOICE" = "Delete a Network" ]; then
			deletenetworkmenu
		elif [ "$CHOICE" = "Launch Nmtui" ]; then
			st -e nmtui &
		elif [ "$CHOICE" = "Launch Ifconfig" ]; then
			st -f Terminus-14 -e watch -n 2 ifconfig &
		elif [ "$CHOICE" = "Scan Wifi Networks" ]; then
			st -f Terminus-14 -e watch -n 2 nmcli d wifi list &
		else
			toggleconnection "$CHOICE"
		fi
	done
}

if [ $# -gt 0 ]; then
	"$@"
else
	networksmenu
fi