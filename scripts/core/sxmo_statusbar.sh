#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

trap "update" USR1
pgrep -f sxmo_statusbar.sh | grep -v $$ | xargs -r kill -9

update() {
	# In-call.. show length of call
	CALLINFO=" "
	if pgrep -f sxmo_modemcall.sh; then
		NOWS="$(date +"%s")"
		CALLSTARTS="$(date +"%s" -d "$(
			grep -aE 'call_start|call_pickup' "$XDG_DATA_HOME"/sxmo/modem/modemlog.tsv |
			tail -n1 |
			cut -f1
		)")"
		CALLSECONDS="$(echo "$NOWS" - "$CALLSTARTS" | bc)"
		CALLINFO="${CALLSECONDS}s"
	fi

	# W symbol if wireless is connect
	WIRELESS=""
	WLANSTATE="$(tr -d "\n" < /sys/class/net/wlan0/operstate)"
	if [ "$WLANSTATE" = "up" ]; then
		WIRELESS=""
	fi

	# M symbol if modem monitoring is on & modem present
	MODEMMON=""
	pgrep -f sxmo_modemmonitor.sh && MODEMMON=""
	if [ -n "$MODEMMON" ]; then
		if [ -f /tmp/modem.locked.state ]; then
			MODEMMON=""
		elif [ -f /tmp/modem.registered.state ]; then
			MODEMMON=""
		elif [ -f /tmp/modem.connected.state ]; then
			MODEMMON=""
		fi
	fi

	# Battery pct
	PCT="$(cat /sys/class/power_supply/*-battery/capacity)"
	BATSTATUS="$(
		cat /sys/class/power_supply/*-battery/status |
		cut -c1
	)"
	if [ "$BATSTATUS" = "C" ]; then
		if [ "$PCT" -lt 20 ]; then
			BATSTATUS=""
		elif [ "$PCT" -lt 30 ]; then
			BATSTATUS=""
		elif [ "$PCT" -lt 40 ]; then
			BATSTATUS=""
		elif [ "$PCT" -lt 60 ]; then
			BATSTATUS=""
		elif [ "$PCT" -lt 80 ]; then
			BATSTATUS=""
		elif [ "$PCT" -lt 90 ]; then
			BATSTATUS=""
		else
			BATSTATUS=""
		fi
	else
		if [ "$PCT" -lt 10 ]; then
			BATSTATUS=""
		elif [ "$PCT" -lt 20 ]; then
			BATSTATUS=""
		elif [ "$PCT" -lt 30 ]; then
			BATSTATUS=""
		elif [ "$PCT" -lt 40 ]; then
			BATSTATUS=""
		elif [ "$PCT" -lt 50 ]; then
			BATSTATUS=""
		elif [ "$PCT" -lt 60 ]; then
			BATSTATUS=""
		elif [ "$PCT" -lt 70 ]; then
			BATSTATUS=""
		elif [ "$PCT" -lt 80 ]; then
			BATSTATUS=""
		elif [ "$PCT" -lt 90 ]; then
			BATSTATUS=""
		else
			BATSTATUS=""
		fi
	fi

	# Volume
	AUDIODEV="$(sxmo_audiocurrentdevice.sh)"
	AUDIOSYMBOL=$(echo "$AUDIODEV" | cut -c1)
	if [ "$AUDIOSYMBOL" = "L" ] || [ "$AUDIOSYMBOL" = "N" ]; then
		AUDIOSYMBOL="" #speakers or none, use no special symbol
	elif [ "$AUDIOSYMBOL" = "H" ]; then
		AUDIOSYMBOL=" "
	elif [ "$AUDIOSYMBOL" = "E" ]; then
		AUDIOSYMBOL=" " #earpiece
	fi
	VOL=0
	[ "$AUDIODEV" = "None" ] || VOL="$(
		amixer sget "$AUDIODEV" |
		grep -oE '([0-9]+)%' |
		tr -d ' %' |
		awk '{ s += $1; c++ } END { print s/c }'  |
		xargs printf %.0f
	)"
	if [ "$AUDIODEV" != "None" ]; then
		if [ "$VOL" -eq 0 ]; then
			VOLUMESYMBOL="ﱝ"
		elif [ "$VOL" -lt 25 ]; then
			VOLUMESYMBOL="奄"
		elif [ "$VOL" -gt 75 ]; then
			VOLUMESYMBOL="墳"
		else
			VOLUMESYMBOL="奔"
		fi
	fi
	# Time
	TIME="$(date +%R)"

	BAR="${CALLINFO} ${MODEMMON} ${WIRELESS} ${AUDIOSYMBOL}${VOLUMESYMBOL} ${BATSTATUS} ${TIME}"
	xsetroot -name "$BAR"
}

# E.g. on first boot justs to make sure the bar comes in quickly
update && sleep 1 && update && sleep 1

while :
do
	update
	sleep 30 & wait
done
