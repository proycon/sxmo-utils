#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

confirm() {
	PICKED="$(printf "Yes\nNo\n" | sxmo_dmenu.sh -p "Confirm $1")"

	if [ "$PICKED" = "Yes" ]; then
		return 0
	else
		return 1
	fi
}

supertoggle_daemon() {
	if superctl status "$1" | grep -q started; then
		superctl stop "$1"
		sxmo_notify_user.sh "$1 Stopped"
	else
		superctl start "$1"
		sxmo_notify_user.sh "$1 Started"
	fi

}

toggle_daemon() {
	name="$1"
	shift

	if sxmo_jobs.sh running "$1" -q; then
		sxmo_jobs.sh stop "$@"
		notify-send "$name Stopped"
	else
		sxmo_jobs.sh start "$@" &
		notify-send "$name Started"
	fi
}

sxmo_type() {
	sxmo_type.sh -s 200 "$@" # dunno why this is necessary but it sucks without
}

call_entries() {
	shown_incall_menu=
	sxmo_modemcall.sh list_active_calls | while read -r line; do
		case "$line" in
			*"(ringing-in)")
				CALLID="$(printf %s "$line" | cut -d" " -f1 | xargs basename)"
				NUMBER="$(sxmo_modemcall.sh vid_to_number "$CALLID")"
				CONTACT="$(sxmo_contacts.sh --name "$NUMBER")"

				printf "%s Incoming call %s ^ 0 ^ sxmo_jobs.sh start incall_menu sxmo_modemcall.sh incoming_call_menu %s\n" \
					"$icon_phn" "$CONTACT" "$CALLID"
				;;
			*)
				[ -n "$shown_incall_menu" ] && continue
				shown_incall_menu=1
				printf "%s Incall Menu ^ 0 ^ sxmo_jobs.sh start incall_menu sxmo_modemcall.sh incall_menu\n" \
					"$icon_phn"
				;;
		esac
	done

}

getprogchoices() {
	RES="$(sxmo_hook_contextmenu.sh "$1")"
	if [ -n "$RES" ]; then
		WINNAME="$(printf %s "$RES" | head -n1)"
		CHOICES="$(printf %s "$RES" | tail -n+2)"
	fi

	# For the Sys menu decorate at top with notifications if >1 notification
	if [ "$WINNAME" = "Sys" ]; then
		NNOTIFICATIONS="$(find "$SXMO_NOTIFDIR" -type f | wc -l)"
		if [ "$NNOTIFICATIONS" -gt 0 ]; then
			CHOICES="
				$icon_bel Notifications ($NNOTIFICATIONS) ^ 0 ^ sxmo_notifs.sh menu
				$CHOICES
			"
		fi
	fi

	CHOICES="
		$(call_entries)
		$CHOICES
	"

	# Decorate menu at bottom w/ system menu entry if not system menu
	echo "$WINNAME" | grep -qv Sys && CHOICES="
		$CHOICES
		$icon_mnu System Menu   ^ 0 ^ sxmo_appmenu.sh sys
	"

	# Decorate menu at bottom w/ close menu entry
	CHOICES="
		$CHOICES
		$icon_cls Close Menu    ^ 0 ^ quit
	"

	CHOICES="$(printf "%s\n" "$CHOICES" | xargs -0 echo | sed '/^[[:space:]]*$/d' | awk '{$1=$1};1')"
}

quit() {
	exit 0
}

mainloop() {
	getprogchoices "$@"
	PICKED="$(
		printf "%s\n" "$CHOICES" |
		cut -d'^' -f1 |
		sxmo_dmenu.sh -i -p "$WINNAME"
	)" || quit

	CHOICE="$(echo "$CHOICES" | awk -F '^' -v picked="$PICKED" \
		'$1 == picked {print $2 "^" $3}'
	)"

	LOOP="$(echo "$CHOICE" | cut -d '^' -f1)"
	CMD="$(echo "$CHOICE" | cut -d '^' -f2)"

	if [ -z "$CMD" ]; then
		printf "%s\n" "sxmo_appmenu: Fallback: unknown choice <$PICKED> to contextmenu_fallback hook">&2
		sxmo_hook_contextmenu_fallback.sh "$WINNAME" "$PICKED"
		quit
	fi

	printf 'sxmo_appmenu: Eval: <%s> from picked <%s> with loop <%s>\n' \
		"$CMD" "$PICKED" "$LOOP" >&2

	if printf %s "$LOOP" | grep -q 1; then
		eval "$CMD"
		mainloop "$@"
	else
		eval "$CMD"
		quit
	fi
}

# Allow loading from shellspec
if [ -z "$SHELLSPEC_PATH" ]; then
	mainloop "$@"
fi
