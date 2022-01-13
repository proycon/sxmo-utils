#!/bin/sh

ROOT="$XDG_RUNTIME_DIR/sxmo_daemons"
mkdir -p "$ROOT"

list() {
	find "$ROOT" -exec 'basename' '{}' ';' -mindepth 1
}

stop() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-f)
				force=1
				shift
				;;
			*)
				id="$1"
				shift
				break
				;;
		esac
	done

	case "$id" in
		all)
			list | while read -r sub_id; do
				stop "$sub_id"
			done
			;;
		*)
			if [ -f "$ROOT/$id" ]; then
				xargs kill ${force:+-9} < "$ROOT"/"$id"
				rm "$ROOT"/"$id"
			fi
			;;
	esac
}

start() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
			--no-restart)
				no_restart=1
				shift
				;;
			*)
				id="$1"
				shift
				break
				;;
		esac
	done

	if [ -f "$ROOT/$id" ]; then
		if [ -n "$no_restart" ]; then
			printf "%s already running\n" "$id"
			exit 1
		else
			stop "$id"
		fi
	fi

	"$@" &
	printf "%s\n" "$!" > "$ROOT"/"$id"
}

running() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-q)
				quiet=1
				shift
				;;
			*)
				id="$1"
				shift
				;;
		esac
	done

	log() {
		if [ -z "$quiet" ]; then
			# shellcheck disable=SC2059
			printf "$@"
		fi
	}

	if [ -f "$ROOT/$id" ]; then
		pid="$(cat "$ROOT/$id")"
		if [ -d "/proc/$pid" ]; then
			log "%s is still running\n" "$id"
		else
			log "%s is not running anymore\n" "$id"
			exit 2
		fi
	else
		log "%s is not running\n" "$id"
		exit 1
	fi
}

"$@"
