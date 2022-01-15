#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"
# shellcheck source=scripts/core/sxmo_icons.sh
. "$(dirname "$0")/sxmo_icons.sh"

set -e

_prompt() {
	sxmo_dmenu.sh -i "$@"
}

_device_list() {
	bluetoothctl devices | \
		cut -d" " -f2 | \
		xargs -n1 bluetoothctl info | \
		awk -v "bluetooth_icon=$icon_btd" '
			function print_cached_device() {
				print icon " " name " " mac
				name=icon=mac=""
			}
			{ $1=$1 }
			/Device/ && name { print_cached_device() }
			/Device/ { mac=$2 }
			/Name:/ { $1="";$0=$0;$1=$1; name=$0 }
			/Icon:/ { icon=bluetooth_icon }
			END { print_cached_device() }
		'
}

_restart_bluetooth() {
	case "$OS" in
		alpine|postmarketos)
			_can_fail sxmo_terminal.sh doas rc-service bluetooth restart
			;;
		arch|archarm)
			_can_fail sxmo_terminal.sh doas systemctl restart bluetooth
			;;
	esac
}

_full_reconnection() {
	_can_fail sxmo_terminal.sh sh -ce "
notify-send 'Make the device discoverable'

bluetoothctl remove '$1' &
sxmo_daemons.sh start bluetooth_scan bluetoothctl scan on

sleep 5

while : ; do
	bluetoothctl --timeout 5 pair '$1'
	if bluetoothctl info '$1'  | grep -q 'Paired: yes'; then
		break
	fi
done

sleep 1

bluetoothctl trust '$1'
bluetoothctl --timeout 7 connect '$1'

sxmo_daemons.sh stop bluetooth_scan
"
}

_notify_failure() {
	notify-send "Something failed"
}

_can_fail() {
	"$@" || _notify_failure
}

_show_toggle() {
	if [ "$1" = yes ]; then
		printf %s "$icon_ton"
	else
		printf %s "$icon_tof"
	fi
}

device_loop() {
	DEVICE="$1"
	MAC="$(printf "%s\n" "$DEVICE" | awk '{print $NF}')"
	INDEX=0
	while : ; do
		INFO="$(bluetoothctl info "$MAC")"
		PAIRED="$(printf "%s\n" "$INFO" | grep "Paired:" | awk '{print $NF}')"
		TRUSTED="$(printf "%s\n" "$INFO" | grep "Trusted:" | awk '{print $NF}')"
		BLOCKED="$(printf "%s\n" "$INFO" | grep "Blocked:" | awk '{print $NF}')"
		CONNECTED="$(printf "%s\n" "$INFO" | grep "Connected:" | awk '{print $NF}')"

		PICK="$(
			cat <<EOF |
$icon_ret Return
$icon_rld Refresh
Paired $(_show_toggle "$PAIRED")
Trusted $(_show_toggle "$TRUSTED")
Connected $(_show_toggle "$CONNECTED")
Blocked $(_show_toggle "$BLOCKED")
$icon_ror Clean re-connection
$icon_trh Remove
EOF
			_prompt -p "$DEVICE" -I "$INDEX"
		)"

		case "$PICK" in
			"$icon_ret Return")
				INDEX=0
				return
				;;
			"$icon_rld Refresh")
				INDEX=1
				continue
				;;
			"Paired $icon_tof")
				INDEX=2
				_can_fail sxmo_terminal.sh bluetoothctl --timeout 7 pair "$MAC"
				;;
			"Trusted $icon_ton")
				INDEX=3
				sxmo_terminal.sh bluetoothctl untrust "$MAC"
				;;
			"Trusted $icon_tof")
				INDEX=3
				sxmo_terminal.sh bluetoothctl trust "$MAC"
				;;
			"Connected $icon_ton")
				INDEX=4
				_can_fail sxmo_terminal.sh bluetoothctl --timeout 7 disconnect "$MAC"
				;;
			"Connected $icon_tof")
				INDEX=4
				_can_fail sxmo_terminal.sh bluetoothctl --timeout 7 connect "$MAC"
				;;
			"Blocked $icon_ton")
				INDEX=5
				;;
			"Blocked $icon_tof")
				INDEX=5
				;;
			"$icon_ror Clean re-connection")
				_full_reconnection "$MAC"
				INDEX=6
				;;
			"$icon_trh Remove")
				INDEX=7
				(confirm_menu -p "Remove this device ?" \
					&& _can_fail sxmo_terminal.sh bluetoothctl remove "$MAC") \
					|| continue
				return
				;;
		esac
		sleep 0.5
	done
}

main_loop() {
	INDEX=0
	while : ; do
		INFO="$(bluetoothctl show)"
		DISCOVERING="$(printf "%s\n" "$INFO" | grep "Discovering:" | awk '{print $NF}')"

		DEVICES="$(_device_list)"

		PICK="$(
			cat <<EOF |
$icon_cls Close Menu
$icon_rld Refresh
$icon_pwr Restart daemon
Discovering $(_show_toggle "$DISCOVERING")
$DEVICES
EOF
			_prompt -p "$icon_bth Bluetooth" -I "$INDEX"
		)"

		case "$PICK" in
			"$icon_cls Close Menu")
				INDEX=0
				exit
				;;
			"$icon_rld Refresh")
				INDEX=1
				continue
				;;
			"$icon_pwr Restart daemon")
				INDEX=2
				confirm_menu -p "Restart the daemon ?" && _restart_bluetooth
				;;
			"Discovering $icon_ton")
				INDEX=3
				sxmo_daemons.sh stop bluetooth_scan
				sleep 0.5
				;;
			"Discovering $icon_tof")
				sxmo_daemons.sh start bluetooth_scan bluetoothctl --timeout 60 scan on > /dev/null
				notify-send "Scanning for 60 seconds"
				INDEX=3
				sleep 0.5
				;;
			*)
				INDEX=0
				device_loop "$PICK"
				;;
		esac
	done
}

main_loop
