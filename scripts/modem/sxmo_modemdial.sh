#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

set -e

dial_number() {

	# on pinepone if you attempt to make a call while in a call, modem crashes
	if sxmo_modemcall.sh list_active_calls | grep -q .; then
		sxmo_notify_user.sh "Cannot make call while in a call (for now)."
		return 0
	fi

	NUMBER="$1"

	CLEANEDNUMBER="$(pnc find ${DEFAULT_COUNTRY:+-c "$DEFAULT_COUNTRY"} "$1")"
	if [ -n "$CLEANEDNUMBER" ] && [ "$NUMBER" != "$CLEANEDNUMBER" ]; then
		NUMBER="$(cat <<EOF | sxmo_dmenu.sh -p "Rewrite ?"
$NUMBER
$CLEANEDNUMBER
EOF
		)"
	fi

	sxmo_log "Attempting to dial: $NUMBER"

	if ! CALLID="$(
		mmcli -m any --voice-create-call "number=$NUMBER" |
		grep -Eo "Call/[0-9]+" |
		grep -oE "[0-9]+"
	)"; then
		sxmo_notify_user.sh --urgency=critical "We failed to initiate call"
		return 1
	fi

	# cleanup all dangling event files, ignore errors
	rm "$XDG_RUNTIME_DIR/sxmo_calls/$CALLID."* 2>/dev/null || true
	sxmo_log "Starting call with CALLID: $CALLID"

	if ! sxmo_modemaudio.sh setup_audio; then
		sxmo_notify_user.sh --urgency=critical "We failed to setup call audio"
		mmcli -m any --voice-delete-call="$CALLID"
		return 1
	fi

	if ! sxmo_modemcall.sh pickup "$CALLID"; then
		sxmo_modemaudio.sh reset_audio
		mmcli -m any --voice-delete-call="$CALLID"
		return 1
	fi

	sxmo_jobs.sh start proximity_lock sxmo_proximitylock.sh
	sxmo_hook_statusbar.sh state &

	sxmo_jobs.sh start incall_menu sxmo_modemcall.sh incall_menu
}

dial_menu() {
	# Initial menu with recently contacted people
	NUMBER="$(
		grep . <<EOF | sxmo_dmenu.sh -p Number -i
Close Menu
More contacts
$(sxmo_contacts.sh --no-groups)
EOF
	)"

	# Submenu with all contacts
	if [ "$NUMBER" = "More contacts" ]; then
		NUMBER="$(
			grep . <<EOF | sxmo_dmenu.sh -p Number -i
Close Menu
$(sxmo_contacts.sh --all --no-groups)
EOF
		)"
	fi

	NUMBER="$(printf "%s\n" "$NUMBER" | cut -d: -f2 | tr -d -- '- ')"
	if [ -z "$NUMBER" ] || [ "$NUMBER" = "CloseMenu" ]; then
		exit 0
	fi

	dial_number "$NUMBER"
}

if [ -n "$1" ]; then
	dial_number "$1"
else
	dial_menu
fi
