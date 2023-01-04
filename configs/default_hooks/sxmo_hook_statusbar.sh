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

set_time() {
	date "+${SXMO_STATUS_DATE_FORMAT:-%H:%M}" | while read -r date; do
		sxmobar -a time 99 "$date"
	done
}

set_state() {
	if grep -q unlock "$SXMO_STATE"; then
		sxmobar -d state
	else
		STATE_LABEL=$(tr '[:lower:]' '[:upper:]' < "$SXMO_STATE")
		sxmobar -a -e bold -b red state 0 "$STATE_LABEL"
	fi
}

set_modem() {
	MMCLI="$(mmcli -m any -J 2>/dev/null)"

	MODEMSTATUSCMP=""
	MODEMTECHCMP=""

	bgcolor=default
	fgcolor=default
	style=normal

	if [ -z "$MMCLI" ]; then
		MODEMSTATUSCMP="$icon_cls"
	else
		MODEMSTATUS="$(printf %s "$MMCLI" | jq -r .modem.generic.state)"
		case "$MODEMSTATUS" in
			locked)
				fgcolor=red
				MODEMSTATUSCMP="$icon_plk"
				;;
			initializing)
				MODEMSTATUSCMP="I"
				;;
			disabled) # low power state
				fgcolor=red
				MODEMSTATUSCMP="$icon_mdd"
				;;
			disabling)
				fgcolor=orange
				MODEMSTATUSCMP="$icon_ena"
				;;
			enabling) # modem enabled but neither registered (cell) nor connected (data)
				fgcolor=green
				MODEMSTATUSCMP="$icon_ena"
				;;
			enabled)
				MODEMSTATUSCMP="$icon_ena"
				;;
			searching) # i.e. registering
				MODEMSTATUSCMP="$icon_dot"
				;;
			registered|connected|connecting|disconnecting)
				MODEMSIGNAL="$(printf %s "$MMCLI" | jq -r '.modem.generic."signal-quality".value')"
				if [ "$MODEMSIGNAL" -lt 20 ]; then
					fgcolor=red
					MODEMSTATUSCMP=""
				elif [ "$MODEMSIGNAL" -lt 40 ]; then
					MODEMSTATUSCMP=""
				elif [ "$MODEMSIGNAL" -lt 60 ]; then
					MODEMSTATUSCMP=""
				elif [ "$MODEMSIGNAL" -lt 80 ]; then
					MODEMSTATUSCMP=""
				else
					MODEMSTATUSCMP=""
				fi
				;;
			*)
				# FAILED, UNKNOWN
				# see https://www.freedesktop.org/software/ModemManager/doc/latest/ModemManager/ModemManager-Flags-and-Enumerations.html#MMModemState
				sxmo_log "WARNING: MODEMSTATUS: $MODEMSTATUS"
				;;
		esac
	fi

	sxmobar -a -f "$fgcolor" -b "$bgcolor" -t "$style" \
		modem-icon 10 "$MODEMSTATUSCMP"

	bgcolor=default
	fgcolor=default
	style=normal

	case "$MODEMSTATUS" in
		connected|registered|connecting|disconnecting)
			case "$MODEMSTATUS" in
				registered)
					fgcolor="red"
					;;
				connecting)
					fgcolor="green"
					;;
				disconnecting)
					fgcolor="orange"
					;;
			esac
			USEDTECHS="$(printf %s "$MMCLI" | jq -r '.modem.generic."access-technologies"[]')"
			case "$USEDTECHS" in
				*5gnr*)
					MODEMTECHCMP="5g" # no icon yet
					;;
				*lte*)
					MODEMTECHCMP="4g" # ﰒ is in the bad range
					;;
				*umts*|*hsdpa*|*hsupa*|*hspa*|*1xrtt*|*evdo0*|*evdoa*|*evdob*)
					MODEMTECHCMP="3g" # ﰑ is in the bad range
					;;
				*edge*)
					MODEMTECHCMP="E"
					;;
				*pots*|*gsm*|*gprs*)
					MODEMTECHCMP="2g" # ﰐ is in the bad range
					;;
				*)
					sxmo_log "WARNING: USEDTECHS: $USEDTECHS"
					MODEMTECHCMP="($USEDTECHS)"
					;;
			esac
			;;
	esac

	sxmobar -a -f "$fgcolor" -b "$bgcolor" -t "$style" \
		modem-status 11 "$MODEMTECHCMP"
}

set_wifi() {
	case "$(cat "/sys/class/net/$2/operstate")" in
		"up")
			# detect hotspot
			if nmcli -g UUID c show --active | while read -r uuid; do
				nmcli -g 802-11-wireless.mode c show "$uuid"
			done | grep -q '^ap$'; then
				sxmobar -a "network-$2-status" 30 "$icon_wfh"
			else
				sxmobar -a "network-$2-status" 30 "$icon_wif"
			fi
			;;
		*)
			if rfkill list wifi | grep -q "yes"; then
				sxmobar -a "network-$2-status" 30 "$icon_wif"
			else
				sxmobar -a -f red "network-$2-status" 30 "$icon_wif"
			fi
			;;
	esac
}

set_vpn() {
	if nmcli -g GENERAL.STATE device show "$2" | grep connected > /dev/null; then
		sxmobar -a "network-$2-status" 30 "$icon_key"
	else
		sxmobar -d "network-$2-status"
	fi
}

# $1: type (reported by nmcli)
# $2: interface name
set_network() {
	case "$1" in
		wifi) set_wifi "$@" ;;
		wireguard|vpn) set_vpn "$@" ;;
		# the type will be empty if the interface disappeared
		"") sxmobar -d "network-$2-status" ;;
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

			if [ -z "$SXMO_BAR_HIDE_BAT_PER" ]; then
				 sxmobar -a battery-status 41 "$PCT%"
			else
				 sxmobar -d battery-status
			fi
		fi
	done
}

set_lockedby() {
	sxmo_mutex.sh can_suspend list | sort -u | while read -r line; do
		case "$line" in
			"SSH"*|"Mosh"*)
				printf "S\n"
				;;
			"Hotspot"*)
				printf "H\n"
				;;
			"Camera postprocessing")
				printf "C\n"
				;;
			"Proximity lock is running")
				printf "P\n"
				;;
			"Ongoing call")
				printf "O\n"
				;;
			"Modem is used")
				printf "M\n"
				;;
			"Executing cronjob")
				printf "X\n"
				;;
			"Waiting for cronjob")
				printf "W\n"
				;;
			"Manually disabled")
				printf "N\n" #N = No suspend
				;;
			"Playing with leds"|"Checking some mutexes")
				printf "*\n"
				;;
			*"is playing"*)
				printf "%s\n" "$icon_mus"
				;;
			*)
				printf "%s\n" "$line" | sed 's/\(.\{7\}\).*/\1…/g'
				;;
		esac
	done | sort -u | tr -d '\n' | while read -r lockedby; do
		sxmobar -a lockedby-status 44 "$lockedby"
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

case "$1" in
	network)
		shift
		set_network "$@"
		;;
	time|modem|battery|volume|state|lockedby|notifications)
		set_"$1"
		;;
	periodics|state_change) # 55 s loop and screenlock triggers
		set_time
		set_modem
		set_battery
		set_state
		;;
	all)
		sxmobar -r
		set_time
		set_modem
		set_battery
		set_volume
		set_state
		set_notifications
		set_lockedby
		;;
	*)
		exit # swallow it !
		;;
esac

