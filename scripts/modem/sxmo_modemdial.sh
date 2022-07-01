#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

set -e

dial_number() {
	NUMBER="$1"

	CLEANEDNUMBER="$(pn find ${DEFAULT_COUNTRY:+-c "$DEFAULT_COUNTRY"} "$1")"
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
		return 1
	fi

	if ! sxmo_modemcall.sh pickup "$CALLID"; then
		sxmo_modemaudio.sh reset_audio
		return 1
	fi

	# do not duplicate proximity lock if already running
	if ! sxmo_daemons.sh running proximity_lock -q; then
		sxmo_daemons.sh start calling_proximity_lock sxmo_hook_proximitylock.sh
	fi

	sxmo_daemons.sh start incall_menu sxmo_modemcall.sh incall_menu
}

dial_menu() {
	# Initial menu with recently contacted people
	NUMBER="$(
		grep . <<EOF | sxmo_dmenu_with_kb.sh -p Number -i
Close Menu
More contacts
$(sxmo_contacts.sh)
EOF
	)"

	# Submenu with all contacts
	if [ "$NUMBER" = "More contacts" ]; then
		NUMBER="$(
			grep . <<EOF | sxmo_dmenu_with_kb.sh -p Number -i
Close Menu
$(sxmo_contacts.sh --all)
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
