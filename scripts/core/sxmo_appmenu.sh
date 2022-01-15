#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_icons.sh
. "$(dirname "$0")/sxmo_icons.sh"
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

confirm() {
	PICKED="$(printf "Yes\nNo\n" | sxmo_dmenu.sh -p "Confirm $1")"

	if [ "$PICKED" = "Yes" ]; then
		return 0
	else
		return 1
	fi
}

toggle_daemon() {
	name="$1"
	shift

	if sxmo_daemons.sh running "$1" -q; then
		sxmo_daemons.sh stop "$@"
		notify-send "$name Stopped"
	else
		sxmo_daemons.sh start "$@" &
		notify-send "$name Started"
	fi
}

sxmo_type() {
	sxmo_type.sh -s 200 "$@" # dunno why this is necessary but it sucks without
}

getprogchoices() {
	RES="$(sxmo_hooks.sh contextmenu "$1")"
	if [ -n "$RES" ]; then
		WINNAME="$(printf %s "$RES" | head -n1)"
		CHOICES="$(printf %s "$RES" | tail -n+2)"
	fi

	# For the Sys menu decorate at top with notifications if >1 notification
	if [ "$WINNAME" = "Sys" ]; then
		NNOTIFICATIONS="$(find "$NOTIFDIR" -type f | wc -l)"
		if [ "$NNOTIFICATIONS" -gt 0 ]; then
			CHOICES="
				$icon_bel Notifications ($NNOTIFICATIONS) ^ 0 ^ sxmo_notificationsmenu.sh
				$CHOICES
			"
		fi
	fi

	#shellcheck disable=SC2044
	for NOTIFFILE in $(find "$NOTIFDIR" -name 'incomingcall*_notification'); do
		NOTIFACTION="$(head -n1 "$NOTIFFILE")"
		MESSAGE="$(tail -1 "$NOTIFFILE")"
		CHOICES="
			$icon_phn $MESSAGE ^ 0 ^ $NOTIFACTION
			$CHOICES
		"
		break
	done

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
	LOOP="$(printf "%s\n" "$CHOICES" | grep -m1 -F "$PICKED" | cut -d '^' -f2)"
	CMD="$(printf "%s\n" "$CHOICES" | grep -m1 -F "$PICKED" | cut -d '^' -f3)"

	printf "%s\n" "sxmo_appmenu: Eval: <$CMD> from picked <$PICKED> with loop <$LOOP>">&2

	if printf %s "$LOOP" | grep -q 1; then
		eval "$CMD"
		mainloop "$@"
	else
		eval "$CMD"
		quit
	fi
}

mainloop "$@"
