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

#colours using pango markup
if [ "$SXMO_WM" = "sway" ]; then
	SPAN_RED="<span foreground=\"#ff5454\">"
	SPAN_REDBG="<span foreground=\"#ffffff\" background=\"#ff5454\">"
	SPAN_GREEN="<span foreground=\"#54ff54\">"
	SPAN_ORANGE="<span foreground=\"#ffa954\">"
	BOLD="<b>"
	ENDBOLD="</b>"
	ENDSPAN="</span>"
else
	SPAN_RED=""
	SPAN_REDBG=""
	SPAN_GREEN=""
	SPAN_ORANGE=""
	BOLD=""
	ENDBOLD=""
	ENDSPAN=""
fi

set_time() {
	date "+${SXMO_STATUS_DATE_FORMAT:-%H:%M}" | head -c -1 | sxmo_status.sh add 99-time
}

set_state() {
	if grep -q unlock "$SXMO_STATE"; then
		sxmo_status.sh del 0-state
	else
		STATE_LABEL=$(tr '[:lower:]' '[:upper:]' < "$SXMO_STATE")
		printf "%b%b%s%b%b" "${SPAN_REDBG}" "${BOLD}" "${STATE_LABEL}" "${ENDBOLD}" "${ENDSPAN}" | sxmo_status.sh add 0-state
	fi
}

set_call_duration() {
	if ! pgrep sxmo_modemcall.sh > /dev/null; then
		sxmo_status.sh del 0-call-duration
		return
	fi

	NOWS="$(date +"%s")"
	CALLSTARTS="$(date +"%s" -d "$(
		grep -aE 'call_start|call_pickup' "$XDG_DATA_HOME"/sxmo/modem/modemlog.tsv |
		tail -n1 |
		cut -f1
	)")"
	CALLSECONDS="$(printf "%s - %s" "$NOWS" "$CALLSTARTS" | bc)"
	printf "%ss " "$CALLSECONDS" | sxmo_status.sh add 5-call-duration
}

_modem() {
	MMCLI="$(mmcli -m any -J 2>/dev/null)"
	MODEMSTATUS=""

	if [ -z "$MMCLI" ]; then
		printf "%s" "$icon_cls"
	else
		MODEMSTATUS="$(printf %s "$MMCLI" | jq -r .modem.generic.state)"
		case "$MODEMSTATUS" in
			locked)
				printf "%s%s%s" "$SPAN_RED" "$icon_plk" "$ENDSPAN"
				;;
			initializing)
				printf "I"
				;;
			disabled) # low power state
				printf "%s%s%s" "$SPAN_RED" "$icon_mdd" "$ENDSPAN"
				;;
			disabling)
				printf "%s%s%s" "$SPAN_ORANGE" "$icon_ena" "$ENDSPAN"
				;;
			enabling) # modem enabled but neither registered (cell) nor connected (data)
				printf "%s%s%s" "$SPAN_GREEN" "$icon_ena" "$ENDSPAN"
				;;
			enabled)
				printf "%s" "$icon_ena"
				;;
			searching) # i.e. registering
				printf "%s" "$icon_dot"
				;;
			registered|connected|connecting|disconnecting)
				MODEMSIGNAL="$(printf %s "$MMCLI" | jq -r '.modem.generic."signal-quality".value')"
				if [ "$MODEMSIGNAL" -lt 20 ]; then
					printf "%s%s" "$SPAN_RED" "$ENDSPAN"
				elif [ "$MODEMSIGNAL" -lt 40 ]; then
					printf ""
				elif [ "$MODEMSIGNAL" -lt 60 ]; then
					printf ""
				elif [ "$MODEMSIGNAL" -lt 80 ]; then
					printf ""
				else
					printf ""
				fi
				;;
			*)
				# FAILED, UNKNOWN
				# see https://www.freedesktop.org/software/ModemManager/doc/latest/ModemManager/ModemManager-Flags-and-Enumerations.html#MMModemState
				sxmo_log "WARNING: MODEMSTATUS: $MODEMSTATUS"
				printf "%s" "$MODEMSTATUS"
				;;
		esac
	fi

	case "$MODEMSTATUS" in
		connected|registered|connecting|disconnecting)
			printf " "
			[ "$MODEMSTATUS" = "registered" ] && printf %s "$SPAN_RED"
			[ "$MODEMSTATUS" = "connecting" ] && printf %s "$SPAN_GREEN"
			[ "$MODEMSTATUS" = "disconnecting" ] && printf %s "$SPAN_ORANGE"
			USEDTECHS="$(printf %s "$MMCLI" | jq -r '.modem.generic."access-technologies"[]')"
			case "$USEDTECHS" in
				*5gnr*)
					printf 5g # no icon yet
					;;
				*lte*)
					printf 4g # ﰒ is in the bad range
					;;
				*umts*|*hsdpa*|*hsupa*|*hspa*|*1xrtt*|*evdo0*|*evdoa*|*evdob*)
					printf 3g # ﰑ is in the bad range
					;;
				*edge*)
					printf E
					;;
				*pots*|*gsm*|*gprs*)
					printf 2g # ﰐ is in the bad range
					;;
				*)
					sxmo_log "WARNING: USEDTECHS: $USEDTECHS"
					printf "(%s)" "$USEDTECHS"
					;;
			esac
			[ "$MODEMSTATUS" = "registered" ] && printf %s "$ENDSPAN"
			[ "$MODEMSTATUS" = "connecting" ] && printf %s "$ENDSPAN"
			[ "$MODEMSTATUS" = "disconnecting" ] && printf %s "$ENDSPAN"
			;;
	esac
}

set_modem() {
	_modem | sxmo_status.sh add 10-modem-status
}

set_wifi() {
	case "$(cat "/sys/class/net/$2/operstate")" in
		"up")
			# detect hotspot
			if nmcli -g UUID c show --active | while read -r uuid; do
				nmcli -g 802-11-wireless.mode c show "$uuid"
			done | grep -q '^ap$'; then
				sxmo_status.sh add "30-network-$2-status" "H"
			else
				sxmo_status.sh add "30-network-$2-status" "$icon_wif"
			fi
			;;
		*)
			sxmo_status.sh add "30-network-$2-status" "$SPAN_RED$icon_wif$ENDSPAN"
			rfkill list wifi | grep -q "yes" && sxmo_status.sh add "30-network-$2-status" "$icon_wfo"
			;;
	esac
}

set_vpn() {
	if nmcli -g GENERAL.STATE device show "$2" | grep connected > /dev/null; then
		sxmo_status.sh add "30-network-$2-status" "$icon_key"
	else
		sxmo_status.sh del "30-network-$2-status"
	fi
}

# $1: type (reported by nmcli)
# $2: interface name
set_network() {
	case "$1" in
		wifi) set_wifi "$@" ;;
		wireguard|vpn) set_vpn "$@" ;;
		# the type will be empty if the interface disappeared
		"") sxmo_status.sh del "30-network-$2-status" ;;
	esac
}

_battery() {
	count=0 # if multiple batteries, add space between them
	for power_supply in /sys/class/power_supply/*; do
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

			if [ "$count" -gt 0 ]; then
				printf " "
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
				printf "ERR"
				continue
			fi

			# Treat 'Full' status as same as 'Charging'
			if [ "$BATSTATUS" = "C" ] || [ "$BATSTATUS" = "F" ]; then
				if [ "$PCT" -lt 20 ]; then
					printf ""
				elif [ "$PCT" -lt 30 ]; then
					printf ""
				elif [ "$PCT" -lt 40 ]; then
					printf ""
				elif [ "$PCT" -lt 60 ]; then
					printf ""
				elif [ "$PCT" -lt 80 ]; then
					printf ""
				elif [ "$PCT" -lt 90 ]; then
					printf ""
				else
					printf "%s%s" "$SPAN_GREEN" "$ENDSPAN"
				fi
			else
				if [ "$PCT" -lt 10 ]; then
					printf "%s%s" "$SPAN_RED" "$ENDSPAN"
				elif [ "$PCT" -lt 20 ]; then
					printf "%s%s" "$SPAN_ORANGE" "$ENDSPAN"
				elif [ "$PCT" -lt 30 ]; then
					printf ""
				elif [ "$PCT" -lt 40 ]; then
					printf ""
				elif [ "$PCT" -lt 50 ]; then
					printf ""
				elif [ "$PCT" -lt 60 ]; then
					printf ""
				elif [ "$PCT" -lt 70 ]; then
					printf ""
				elif [ "$PCT" -lt 80 ]; then
					printf ""
				elif [ "$PCT" -lt 90 ]; then
					printf ""
				else
					printf ""
				fi
			fi

			[ -z "$SXMO_BAR_HIDE_BAT_PER" ] && printf " %s%%" "$PCT"
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
	done | sort -u | tr -d '\n' | sxmo_status.sh add 41-lockedby-status
}

set_battery() {
	 _battery | sxmo_status.sh add 40-battery-status
}

set_notifications() {
       [ "$SXMO_DISABLE_LEDS" = 0 ] && return
       NNOTIFICATIONS="$(find "$SXMO_NOTIFDIR" -type f | wc -l)"
       [ "$NNOTIFICATIONS" = 0 ] && sxmo_status.sh del notifs && return
       printf "%s!: %d%s\n" "$SPAN_RED" "$NNOTIFICATIONS" "$ENDSPAN" | sxmo_status.sh add notifs
}

_volume() {
	if sxmo_modemaudio.sh is_call_audio_mode; then
		printf %s "$SPAN_GREEN"
		sxmo_modemaudio.sh is_muted_mic && printf "%s " "$icon_mmc" || printf "%s " "$icon_mic"
		sxmo_modemaudio.sh is_enabled_speaker && printf %s "$icon_spk" || printf %s "$icon_ear"
		printf %s "$ENDSPAN"
		return
	fi

	sxmo_audio.sh mic ismuted && printf "%s " "$icon_mmc" || printf "%s " "$icon_mic"

	case "$(sxmo_audio.sh device get 2>/dev/null)" in
		Speaker|"")
			# nothing for default or pulse devices
			;;
		Headphones|Headphone)
			printf "%s " "$icon_hdp"
			;;
		Earpiece)
			printf "%s " "$icon_ear"
			;;
	esac

	VOL="$(sxmo_audio.sh vol get)"
	if [ -z "$VOL" ] || [ "$VOL" = "muted" ]; then
		printf "%s" "$icon_mut"
	elif [ "$VOL" -gt 66 ]; then
		printf "%s" "$icon_spk"
	elif [ "$VOL" -gt 33 ]; then
		printf "%s" "$icon_spm"
	elif [ "$VOL" -ge 0 ]; then
		printf "%s" "$icon_spl"
	fi
}

set_volume() {
	 _volume | sxmo_status.sh add 50-volume
}

case "$1" in
	network)
		shift
		set_network "$@"
		;;
	time|call_duration|modem|battery|volume|state|lockedby|notifications)
		set_"$1"
		;;
	periodics|state_change) # 55 s loop and screenlock triggers
		set_time
		set_modem
		set_battery
		set_state
		;;
	all)
		sxmo_status.sh reset
		set_time
		set_call_duration
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

