#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# we disable shellcheck SC2154 (unreferenced variable used)
# shellcheck disable=SC2154

# include common definitions
# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

# You can modify the statusbar ordering and feel here.
# Note that order number runs from 0 (far left) to 100 (far
# right). Our preference is to have "static" icons on the
# right and "variable" icons (that come and go) on the left.

set_time() {
	date "+${SXMO_STATUS_DATE_FORMAT:-%H:%M}" | while read -r date; do
		sxmobar -a time 99 "$date"
	done
}

set_state() {
	if [ ! -f "$SXMO_STATE" ]; then
		return
	fi

	STATE_LABEL="$(cat "$SXMO_STATE")"
	case "$STATE_LABEL" in
		proximity*)
			sxmobar -a -e bold -f orange state 90 "$icon_dop" # circle with dot
			;;
		screenoff)
			sxmobar -a -e bold -f red state 90 "$icon_don" # filled circle
			;;
		lock)
			sxmobar -a -e bold -f red state 90 "$icon_dof" # open circle
			;;
		unlock)
			sxmobar -a -e bold state 90 "$icon_dof" # open circle
			;;
	esac
}

# from right to left: indicate signal, technologies, mm state
set_modem() {
	MMCLI="$(mmcli -m any -J 2>/dev/null)"

	bgcolor=default
	fgcolor=default
	style=normal

	if [ -z "$MMCLI" ]; then
		MODEMSTATE="nomodem"
	else
		MODEMSTATE="$(printf %s "$MMCLI" | jq -r .modem.generic.state)"
	fi

	case "$MODEMSTATE" in
		nomodem)
			fgcolor=red
			MODEMSTATECMP="$icon_modem_nomodem"
			;;
		locked)
			fgcolor=red
			MODEMSTATECMP="$icon_modem_locked"
			;;
		initializing)
			fgcolor=red
			MODEMSTATECMP="$icon_modem_initializing"
			;;
		disabled) # low power state
			fgcolor=red
			MODEMSTATECMP="$icon_modem_disabled"
			;;
		disabling)
			fgcolor=red
			MODEMSTATECMP="$icon_modem_disabling"
			;;
		enabling) # modem enabled but neither registered (cell) nor connected (data)
			fgcolor=red
			MODEMSTATECMP="$icon_modem_enabling"
			;;
		enabled)
			fgcolor=red
			MODEMSTATECMP="$icon_modem_enabled"
			;;
		searching) # i.e. registering
			fgcolor=red
			MODEMSTATECMP="$icon_modem_searching"
			;;
		registered) # i.e. phone but no data
			fgcolor=orange
			MODEMSTATECMP="$icon_modem_registered"
			;;
		connecting)
			fgcolor=orange
			MODEMSTATECMP="$icon_modem_connecting"
			;;
		disconnecting) # i.e., going back to registered state
			fgcolor=orange
			MODEMSTATECMP="$icon_modem_disconnecting"
			;;
		connected)
			MODEMSTATECMP="$icon_modem_connected"
			;;
		*)
			# FAILED, UNKNOWN
			# see https://www.freedesktop.org/software/ModemManager/doc/latest/ModemManager/ModemManager-Flags-and-Enumerations.html#MMModemState
			fgcolor=red
			MODEMSTATECMP="$icon_modem_failed" # cell with !
			sxmo_log "WARNING: MODEMSTATE: $MODEMSTATE"
			;;
	esac

	sxmobar -a -f "$fgcolor" -b "$bgcolor" -t "$style" \
		modem-state 10 "$MODEMSTATECMP"

	if [ "$MODEMSTATE" = nomodem ]; then
		sxmobar -d modem-tech
		sxmobar -d modem-signal
		return
	fi

	MODEMTECHCMP="$icon_modem_notech"
	bgcolor=default
	fgcolor=default
	style=normal

	# see https://www.freedesktop.org/software/ModemManager/api/latest/ModemManager-Flags-and-Enumerations.html#MMModemAccessTechnology
	USEDTECHS="$(printf %s "$MMCLI" | jq -r '.modem.generic."access-technologies"[]')"
		case "$USEDTECHS" in
			*5gnr*)
				MODEMTECHCMP="$icon_modem_fiveg"
				;;
			*lte*) # lte, lte_nb_iot, lte_cat_m
				MODEMTECHCMP="$icon_modem_fourg"
				;;
			*umts*)
				MODEMTECHCMP="$icon_modem_threeg"
				;;
			*hsupa*)
				MODEMTECHCMP="$USEDTECHS" # 3g
				;;
			*hsdpa*)
				MODEMTECHCMP="$USEDTECHS" # 3g
				;;
			*1xrtt*)
				MODEMTECHCMP="$USEDTECHS" # 3g
				;;
			*evdo*) # evdo0, evdoa, evdob
				MODEMTECHCMP="$USEDTECHS" # 3g
				;;
			*hspa_plus*)
				MODEMTECHCMP="$icon_modem_hspa_plus" # 3g
				;;
			*hspa*)
				MODEMTECHCMP="$icon_modem_hspa" # 3g
				;;
			*edge*)
				MODEMTECHCMP="E" # 2G+
				;;
			*pots*)
				MODEMTECHCMP="P" # 0G
				;;
			*gsm*) # gsm, gsm_compact
				MODEMTECHCMP="$icon_modem_twog"
				;;
			*gprs*)
				MODEMTECHCMP="G" # 2G
				;;
			*)
				sxmo_log "WARNING: USEDTECHS: $USEDTECHS"
				fgcolor=red
				;;
		esac

	sxmobar -a -f "$fgcolor" -b "$bgcolor" -t "$style" \
		modem-tech 11 "$MODEMTECHCMP"

	MODEMSIGNALCMP="$icon_modem_signal_0"
	bgcolor=default
	fgcolor=default
	style=normal

	case "$MODEMSTATE" in
		registered|connected|connecting|disconnecting)
			MODEMSIGNAL="$(printf %s "$MMCLI" | jq -r '.modem.generic."signal-quality".value')"
			if [ "$MODEMSIGNAL" -lt 33 ]; then
				MODEMSIGNALCMP="$icon_modem_signal_1"
			elif [ "$MODEMSIGNAL" -lt 66 ]; then
				MODEMSIGNALCMP="$icon_modem_signal_2"
			else
				MODEMSIGNALCMP="$icon_modem_signal_3"
			fi
		;;
	esac

	sxmobar -a -f "$fgcolor" -b "$bgcolor" -t "$style" \
		modem-signal 12 "$MODEMSIGNALCMP"
}

# $1 = type (wifi, tun)
# $2 = interface name (wlan0, tun0)
set_wifi() {

	if rfkill list wifi | grep -q "yes"; then
		sxmobar -d wifi-status
		return
	fi

	CONN="$(nmcli -t con show --active)"

	if ! printf %b "$CONN" | cut -d':' -f3 | grep -q wireless; then
		sxmobar -a -f red wifi-status 30 "$icon_wifi_disconnected"
		return
	fi

	# we simply assume Hotspot as first bit of name
	# for hotspot as this is what we create.
	if printf %b "$CONN" | grep -q ^Hotspot; then
		sxmobar -a wifi-status 30 "$icon_wfh"
		return
	fi

	# if they have a vpn nmcli c shown --active should also list:
	# tun0              ef5fcce9-fdae-4ffe-a540-b16fc7b42852  tun   tun0   
	if printf %b "$CONN" | cut -d':' -f3 | grep -q ^tun$; then
		wifivpn=1
	else
		wifivpn=0
	fi

	wifi_signal="$(nmcli -f IN-USE,SIGNAL,SSID device wifi | awk '/^\*/{if (NR!=1) {print $2}}')"
	if [ -z "$wifi_signal" ]; then
		icon_wif="$icon_wifi_signal_exclam"
	elif [ "$wifi_signal" -lt 20 ]; then
		if [ "$wifivpn" -eq 1 ]; then
			icon_wif="$icon_wifi_key_signal_0"
		else
			icon_wif="$icon_wifi_signal_0"
		fi
	elif [ "$wifi_signal" -lt 40 ]; then
		if [ "$wifivpn" -eq 1 ]; then
			icon_wif="$icon_wifi_key_signal_1"
		else
			icon_wif="$icon_wifi_signal_1"
		fi
	elif [ "$wifi_signal" -lt 60 ]; then
		if [ "$wifivpn" -eq 1 ]; then
			icon_wif="$icon_wifi_key_signal_2"
		else
			icon_wif="$icon_wifi_signal_2"
		fi
	elif [ "$wifi_signal" -lt 80 ]; then
		if [ "$wifivpn" -eq 1 ]; then
			icon_wif="$icon_wifi_key_signal_3"
		else
			icon_wif="$icon_wifi_signal_3"
		fi
	else
		if [ "$wifivpn" -eq 1 ]; then
			icon_wif="$icon_wifi_key_signal_4"
		else
			icon_wif="$icon_wifi_signal_4"
		fi
	fi

	sxmobar -a wifi-status 30 "$icon_wif"
}

# $1: type (reported by nmcli, e.g., wifi, tun)
# $2: interface name (reported by nmcli, e.g., wlan0, tun0)
set_network() {
	case "$1" in
		wifi|tun) set_wifi "$@" ;;
	esac
}

set_battery() {
	count=0 # handle multiple batteries
	for power_supply in /sys/class/power_supply/*; do
		fgcolor=default
		bgcolor=default
		style=normal
		BATCMP=


		if [ "$(cat "$power_supply"/type)" = "Battery" ]; then
			if [ -e "$power_supply"/capacity ]; then
				PCT="$(cat "$power_supply"/capacity)"
			elif [ -e "$power_supply"/charge_now ]; then
				CHARGE_NOW="$(cat "$power_supply"/charge_now)"
				CHARGE_FULL="$(cat "$power_supply"/charge_full_design)"
				PCT="$(printf "scale=2; %s / %s * 100\n" "$CHARGE_NOW" "$CHARGE_FULL" | bc | cut -d'.' -f1)"
			else
				continue
			fi

			count=$((count+1))

			if [ -e "$power_supply"/status ]; then
				# The status is not always given for the battery device.
				# (sometimes it's linked to the charger device).
				BATSTATUS="$(cut -c1 "$power_supply"/status)"
			fi

			# fixes a bug with keyboard case where
			# /sys/class/power_supply/ip5xxx-charger/capacity
			# exists but returns 'Not a tty'
			if [ -z "$PCT" ]; then
				BATCMP="ERR"
			elif [ "$BATSTATUS" = "C" ] || [ "$BATSTATUS" = "F" ]; then
				if [ "$PCT" -lt 20 ]; then
					BATCMP=""
				elif [ "$PCT" -lt 30 ]; then
					BATCMP=""
				elif [ "$PCT" -lt 40 ]; then
					BATCMP=""
				elif [ "$PCT" -lt 60 ]; then
					BATCMP=""
				elif [ "$PCT" -lt 80 ]; then
					BATCMP=""
				elif [ "$PCT" -lt 90 ]; then
					BATCMP=""
				else
					# Treat 'Full' status as same as 'Charging'
					fgcolor=green
					BATCMP=""
				fi
			else
				if [ "$PCT" -lt 10 ]; then
					fgcolor=red
					BATCMP=""
				elif [ "$PCT" -lt 20 ]; then
					fgcolor=orange
					BATCMP=""
				elif [ "$PCT" -lt 30 ]; then
					BATCMP=""
				elif [ "$PCT" -lt 40 ]; then
					BATCMP=""
				elif [ "$PCT" -lt 50 ]; then
					BATCMP=""
				elif [ "$PCT" -lt 60 ]; then
					BATCMP=""
				elif [ "$PCT" -lt 70 ]; then
					BATCMP=""
				elif [ "$PCT" -lt 80 ]; then
					BATCMP=""
				elif [ "$PCT" -lt 90 ]; then
					BATCMP=""
				else
					BATCMP=""
				fi
			fi

			sxmobar -a -t "$style" -b "$bgcolor" -f "$fgcolor" \
				battery-icon 40 "$BATCMP"

			if [ -z "$SXMO_BAR_SHOW_BAT_PER" ]; then
				 sxmobar -d battery-status
			else
				 sxmobar -a battery-status 41 "$PCT%"
			fi
		fi
	done
}

set_notifications() {
	[ -z "$SXMO_DISABLE_LEDS" ] && return
	NNOTIFICATIONS="$(find "$SXMO_NOTIFDIR" -type f | wc -l)"
	if [ "$NNOTIFICATIONS" = 0 ]; then
		sxmobar -d notifs
	else
		sxmobar -a -f red notifs 5 "!: $NNOTIFICATIONS"
	fi
}

set_volume() {
	VOLCMP=""

	if sxmo_modemaudio.sh is_call_audio_mode; then
		if sxmo_modemaudio.sh is_muted_mic; then
			VOLCMP="$icon_mmc"
		else
			VOLCMP="$icon_mic"
		fi
		if sxmo_modemaudio.sh is_enabled_speaker; then
			VOLCMP="$VOLCMP $icon_spk"
		else
			VOLCMP="$VOLCMP $icon_ear"
		fi
		sxmobar -a -f green volume 50 "$VOLCMP"
		return;
	fi

	if sxmo_audio.sh mic ismuted; then
		VOLCMP="$icon_mmc"
	else
		VOLCMP="$icon_mic"
	fi

	case "$(sxmo_audio.sh device get 2>/dev/null)" in
		Speaker|"")
			# nothing for default or pulse devices
			;;
		Headphones|Headphone)
			VOLCMP="$VOLCMP $icon_hdp"
			;;
		Earpiece)
			VOLCMP="$VOLCMP $icon_ear"
			;;
	esac

	VOL="$(sxmo_audio.sh vol get)"
	if [ -z "$VOL" ] || [ "$VOL" = "muted" ]; then
		VOLCMP="$VOLCMP $icon_mut"
	elif [ "$VOL" -gt 66 ]; then
		VOLCMP="$VOLCMP $icon_spk"
	elif [ "$VOL" -gt 33 ]; then
		VOLCMP="$VOLCMP $icon_spm"
	elif [ "$VOL" -ge 0 ]; then
		VOLCMP="$VOLCMP $icon_spl"
	fi

	sxmobar -a volume 50 "$VOLCMP"
}

sxmo_debug "$@"
case "$1" in
	network)
		shift
		set_network "$@"
		;;
	time|modem|battery|volume|state|notifications)
		set_"$1"
		;;
	periodics|state_change) # 55 s loop and screenlock triggers
		set_time
		set_modem
		set_battery
		set_state
		set_network wifi wlan0
		;;
	all)
		sxmobar -r
		set_time
		set_modem
		set_battery
		set_volume
		set_state
		set_notifications
		set_network wifi wlan0
		;;
	*)
		exit # swallow it !
		;;
esac

