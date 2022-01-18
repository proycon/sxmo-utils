#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

set -e

err() {
	sxmo_notify_user.sh "$1"
	exit 1
}

dialnumber() {
	NUMBER="$1"

	CLEANEDNUMBER="$(pn find ${DEFAULT_COUNTRY:+-c "$DEFAULT_COUNTRY"} "$1")"
	if [ -n "$CLEANEDNUMBER" ] && [ "$NUMBER" != "$CLEANEDNUMBER" ]; then
		NUMBER="$(cat <<EOF | sxmo_dmenu.sh -p "Rewrite ?"
$NUMBER
$CLEANEDNUMBER
EOF
		)"
	fi

	printf "Attempting to dial: %s\n" "$NUMBER" >&2
	CALLID="$(
		mmcli -m any --voice-create-call "number=$NUMBER" |
		grep -Eo "Call/[0-9]+" |
		grep -oE "[0-9]+"
	)" || err "Unable to initiate call, is your modem working?"

	find "$SXMO_CACHEDIR" -name "$CALLID.*" -delete # we cleanup all dangling event files
	printf "Starting call with CALLID: %s\n" "$CALLID" >&2
	exec sxmo_modemcall.sh pickup "$CALLID"
}

dialmenu() {
	# Initial menu with recently contacted people
	NUMBER="$(
		cat <<EOF | sxmo_dmenu_with_kb.sh -p Number -i
Close Menu
More contacts
$(sxmo_contacts.sh)
EOF
	)"

	# Submenu with all contacts
	if [ "$NUMBER" = "More contacts" ]; then
		NUMBER="$(
			cat <<EOF | sxmo_dmenu_with_kb.sh -p Number -i
Close Menu
$(sxmo_contacts.sh --all)
EOF
		)"
	fi

	NUMBER="$(printf "%s\n" "$NUMBER" | cut -d: -f2 | tr -d -- '- ')"
	if [ -z "$NUMBER" ] || [ "$NUMBER" = "CloseMenu" ]; then
		exit 0
	fi

	dialnumber "$NUMBER"
}

if [ -n "$1" ]; then
	dialnumber "$1"
else
	dialmenu
fi
