#!/bin/sh
trap "gracefulexit" INT TERM

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

stderr() {
	sxmo_log "$*"
}

gracefulexit() {
	stderr "gracefully exiting (on signal or after error)"
	sxmo_daemons.sh stop modem_monitor_voice
	sxmo_daemons.sh stop modem_monitor_text
	sxmo_daemons.sh stop modem_monitor_finished_voice
	sxmo_daemons.sh stop modem_monitor_state_change
	sxmo_daemons.sh stop modem_monitor_check_daemons
	sxmo_daemons.sh stop modem_monitor_mms
	sxmo_daemons.sh stop modem_monitor_vvm
	exit
}
statenumtoname() {
	case "$*" in
		"int32 -1") pnewstate="FAILED (-1)"
			;;
		"int32 0") pnewstate="UNKNOWN (0)"
			;;
		"int32 1") pnewstate="INITIALIZING (1)"
			;;
		"int32 2") pnewstate="LOCKED (2)"
			;;
		"int32 3") pnewstate="DISABLED (3)"
			;;
		"int32 4") pnewstate="DISABLING (4)"
			;;
		"int32 5") pnewstate="ENABLING (5)"
			;;
		"int32 6") pnewstate="ENABLED (6)"
			;;
		"int32 7") pnewstate="SEARCHING (7)"
			;;
		"int32 8") pnewstate="REGISTERED (8)"
			;;
		"int32 9") pnewstate="DISCONNECTING (9)"
			;;
		"int32 10") pnewstate="CONNECTING (10)"
			;;
		"int32 11") pnewstate="CONNECTED (11)"
			;;
	esac
	printf %s "$pnewstate"
}

mainloop() {
	#these may be premature and return nothing yet (because modem/sim might not be ready yet)
	sxmo_modem.sh checkforfinishedcalls
	sxmo_modem.sh checkforincomingcalls
	sxmo_modem.sh checkfornewtexts
	sxmo_mms.sh checkforlostmms

	sxmo_modem.sh initialmodemstatus

	PIDS=""

	# Monitor for incoming calls
	sxmo_daemons.sh start modem_monitor_voice \
		dbus-monitor --system "interface='org.freedesktop.ModemManager1.Modem.Voice',type='signal',member='CallAdded'" | \
		while read -r line; do
			echo "$line" | grep -E "^signal" && sxmo_modem.sh checkforincomingcalls
		done &
	PIDS="$PIDS $!"

	# Monitor for incoming texts
	sxmo_daemons.sh start modem_monitor_text \
		dbus-monitor --system "interface='org.freedesktop.ModemManager1.Modem.Messaging',type='signal',member='Added'" | \
		while read -r line; do
			echo "$line" | grep -E "^signal" && sxmo_modem.sh checkfornewtexts
		done &
	PIDS="$PIDS $!"

	# Monitor for finished calls
	sxmo_daemons.sh start modem_monitor_finished_voice \
		dbus-monitor --system "interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='org.freedesktop.ModemManager1.Call'" | \
		while read -r line; do
			echo "$line" | grep -E "^signal" && sxmo_modem.sh checkforfinishedcalls
		done &
	PIDS="$PIDS $!"

	sxmo_daemons.sh start modem_monitor_state_change \
		dbus-monitor --system "interface='org.freedesktop.ModemManager1.Modem',type='signal',member='StateChanged'" | \
		while read -r line; do
			if echo "$line" | grep -E "^signal.*StateChanged"; then
				read -r oldstate
				read -r newstate
				read -r reason
				stderr "$(statenumtoname "$oldstate") -> $(statenumtoname "$newstate") [reason: $(echo "$reason" | cut -d' ' -f2)]"
				# 2=MM_MODEM_STATE_LOCKED
				if echo "$newstate" | grep "int32 2"; then
					stderr "calling unlocksim"
					pidof unlocksim || sxmo_hooks.sh unlocksim &
				# 8=MM_MODEM_STATE_REGISTERED
				elif echo "$newstate" | grep "int32 8"; then
					stderr "reloading checks"
					#if there is a PIN entry menu open, kill it:
					# shellcheck disable=SC2009
					ps aux | grep dmenu | grep PIN | gawk '{ print $1 }' | xargs kill 2>/dev/null
					sxmo_modem.sh checkforfinishedcalls
					sxmo_modem.sh checkforincomingcalls
					sxmo_modem.sh checkfornewtexts
					sxmo_mms.sh checkforlostmms
				fi
				sxmo_hooks.sh statusbar modem
			fi
		done &
	PIDS="$PIDS $!"

	# monitor for mms
	sxmo_daemons.sh start modem_monitor_mms \
		dbus-monitor "interface='org.ofono.mms.Service',type='signal',member='MessageAdded'" | \
		while read -r line; do
			if echo "$line" | grep -q '^object path'; then
				MESSAGE_PATH="$(echo "$line" | cut -d'"' -f2)"
			fi
			if echo "$line" | grep -q 'string "received"'; then
				sxmo_mms.sh processmms "$MESSAGE_PATH" "Received"
			fi
		done &
	PIDS="$PIDS $!"

	# monitor for vvm (Visual Voice Mail)
	VVM_START=0
	sxmo_daemons.sh start modem_monitor_vvm \
		dbus-monitor "interface='org.kop316.vvm.Service',type='signal',member='MessageAdded'" | \
		while read -r line; do
			if echo "$line" | grep -q '^object path'; then
				VVM_ID="$(echo "$line" | cut -d'"' -f2 | rev | cut -d'/' -f1 | rev)"
				VVM_START=1
			fi

			if echo "$line" | grep -q '^]'; then
				VVM_START=0
				sxmo_vvm.sh processvvm "$VVM_DATE" "$VVM_SENDER" "$VVM_ID" "$VVM_ATTACHMENT"
			fi

			if [ "$VVM_START" -eq 1 ]; then
				if echo "$line" | grep -q '^string "Date"'; then
					read -r line
					VVM_DATE="$(echo "$line" | cut -d'"' -f2)"
				elif echo "$line" | grep -q '^string "Sender"'; then
					read -r line
					VVM_SENDER="$(echo "$line" | cut -d'"' -f2)"
				elif echo "$line" | grep -q '^string "Attachments"'; then
					read -r line
					VVM_ATTACHMENT="$(echo "$line" | cut -d'"' -f2)"
				fi
			fi
		done &
	PIDS="$PIDS $!"

	for PID in $PIDS; do
		wait "$PID"
	done
}


stderr "starting"
rm -f "$SXMO_CACHEDIR"/*.pickedupcall 2>/dev/null #new session, forget all calls we picked up previously
mainloop
stderr "exiting"
