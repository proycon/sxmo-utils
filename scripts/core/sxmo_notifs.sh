#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh
# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh

_clear_notif_group() {
	find "$SXMO_NOTIFDIR" -type f | while read -r file; do
		if awk NR==1 "$file" | grep -lxq "$1"; then
			rm "$file"
		fi
	done
}

_handle_new_notif_file(){
	file="$1"

	if [ "$(wc -l "$file" | cut -d' ' -f1)" -lt 3 ]; then
		sxmo_log "Invalid notification file $file found, deleting!"
		rm -f "$file"
		return
	fi

	sxmo_hook_notification.sh "$file" &

	group="$(awk NR==1 "$file")"
	action="$(awk NR==2 "$file")"
	msg="$(tail -n+3 "$file" | cut -c1-70)"

	if dunstify --action="2,open" "$msg" | grep -q 2; then
		_clear_notif_group "$group"
		setsid -f sh -c "$action" > /dev/null 2>&1
	fi &
}

_notifications_hook() {
	sxmo_hook_notifications.sh "$(find "$SXMO_NOTIFDIR"/ -type f | wc -l)"
}

monitor() {
	mkdir -p "$SXMO_NOTIFDIR"

	find "$SXMO_NOTIFDIR" -type f | while read -r file; do
		_handle_new_notif_file "$file"
	done

	_notifications_hook

	fifo="$(mktemp -u)"
	mkfifo "$fifo"
	inotifywait -mq -e attrib,move,delete "$SXMO_NOTIFDIR"  >> "$fifo" &
	inotif_pid=$!

	finish() {
		kill "$inotif_pid"
		rm "$fifo"
		exit
	}
	trap 'finish' TERM INT EXIT

	while read -r notif_folder notif_type notif_file; do
		if echo "$notif_type" | grep -qE "CREATE|MOVED_TO|ATTRIB"; then
			_handle_new_notif_file "$notif_folder$notif_file"
		fi
		_notifications_hook
	done < "$fifo"

	wait "$inotif_pid"
}

_menu_lines() {
	find "$SXMO_NOTIFDIR" -type f | while read -r file; do
		msg="$(tail -n+3 "$file" | tr "\n^" " ")"
		hrandmin="$(stat --printf %y "$file" | grep -oE '[0-9]{2}:[0-9]{2}')"
		cat <<EOF
$hrandmin $msg^$file
EOF
	done
}

menu() {
	choices="$(cat <<EOF
$icon_cls Close Menu
$icon_del Clear Notifications
$(_menu_lines)
EOF
	)"

	picked="$(
		printf "%b" "$choices" |
		cut -d^ -f1 |
		sxmo_dmenu.sh -i -p "Notifs"
	)"

	case "$picked" in
		"$icon_cls Close Menu"|"")
			exit
			;;
		"$icon_del Clear Notifications")
			rm "$SXMO_NOTIFDIR"/*
			# we must update statusbar here because this function depends
			# on number of files in $SXMO_NOTIFDIR
			sxmo_hook_statusbar.sh notifications
			exit
			;;
		*)
			file="$(
				printf "%b" "$choices" |
				grep -F "$picked" |
				cut -d^ -f2
			)"
			group="$(awk NR==1 "$file")"
			action="$(awk NR==2 "$file")"
			_clear_notif_group "$group"
			setsid -f sh -c "$action" > /dev/null 2>&1
			;;
	esac
}

new() {
	while : ; do
		case "$1" in
			-i)
				id="$2"
				shift 2
				;;
			-g)
				group="$2"
				shift 2
				;;
			*)
				break
				;;
		esac
	done

	if [ "$#" -lt 2 ]; then
		usage
		exit 1
	fi

	if [ -z "$id" ]; then
		id="$(tr -dc 'a-zA-Z0-9' < /dev/urandom 2>/dev/null | head -c 10)"
	fi
	if [ -z "$group" ]; then
		group="$(tr -dc 'a-zA-Z0-9' < /dev/urandom 2>/dev/null | head -c 10)"
	fi

	action="$1"
	msg="$2"

	touch "$SXMO_NOTIFDIR/$id"
	printf "%s\n%s\n%b\n" "$group" "$action" "$msg" > "$SXMO_NOTIFDIR/$id"

	sxmo_hook_statusbar.sh notifications
}

usage() {
	cat <<EOF
$(basename "$0"): manage sxmo notifications

Subcommands:
	monitor
		Watch for new notification, dispatch libnotify events, handle actions
	menu
		Open a menu to dismiss notifications
	new [-i id] [-g group] <action> <message...>
		Register a new notification
EOF
}

cmd="$1"
shift
case "$cmd" in
	monitor) monitor "$@";;
	menu) menu "$@";;
	new) new "$@";;
	*)
		usage
		exit 1
		;;
esac
