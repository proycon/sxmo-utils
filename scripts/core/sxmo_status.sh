#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# A pretty generic status content generator
# It aggregate all file content present in a folder
# It sort file elements numerically
# It can watch file events to stdout new content

ROOT="$XDG_RUNTIME_DIR/sxmo_status/${SXMO_STATUS_NAME:-default}"
mkdir -p "$ROOT"

_sorted_components_name() {
	find "$ROOT" -mindepth 1 -exec 'basename' '{}' ';' | sort -n
}

usage() {
	printf "Usage: %s [ACTIONS]\n" "$(basename "$0")" >&2
	printf "ACTIONS:\n" >&2
	printf "	-s: the status content (default action)\n" >&2
	printf "	-w: file events and stdout status content\n" >&2
	printf "	-a <id> <priority> <content>: add a bar component\n" >&2
	printf "	-d <id>: remove a bar component\n" >&2
	printf "	-r: remove all bar components\n" >&2
	printf "	-D: the status content explained\n" >&2
	printf "	-h: this message\n" >&2
}

add() {
	id=
	priority=
	value=

	while [ -n "$*" ]; do
		arg="$1"
		shift

		case "$arg" in
			"-f"|"-b"|"-t"|"-e")
				shift # we shallow this
				;;
			*)
				if [ -z "$id" ]; then
					id="$arg"
				elif [ -z "$priority" ]; then
					priority="$arg"
				elif [ -z "$value" ]; then
					value="$arg"
				fi
				;;
		esac
	done

	if [ -z "$id" ] || [ -z "$priority" ] || [ -z "$value" ]; then
		printf "usage: %s -a <id> <priority> <value>\n" "$(basename "$0")" >&2
		exit 1
	fi

	del "$id"

	id="$priority-$id"

	if [ -n "$value" ]; then
		printf "%s" "$value" > "$ROOT"/"$id"
	fi
}

del() {
	id="$1"
	shift

	if [ -z "$id" ]; then
		printf "usage: %s -d <id>\n" "$(basename "$0")" >&2
		exit 1
	fi

	_sorted_components_name | grep -m1 "\-$id$" | xargs -rI{} rm -f "$ROOT"/"{}"
}

show() {
	_sorted_components_name | while read -r id; do
		tr '\n' ' ' < "$ROOT/$id"
		printf " "
	done | head -c -1 | tr '\n' '\0' | xargs -0 -n1 printf "%s\n"
}

debug() {
	_sorted_components_name | while read -r id; do
		printf "%s\n>" "$id"
		tr '\n' ' ' < "$ROOT/$id"
		printf "<\n"
	done
}

watch() {
	FIFO="$(mktemp -u)"
	mkfifo "$FIFO"
	inotifywait -mq -e "close_write,move,delete" "$ROOT" >> "$FIFO" &
	NOTIFYPID=$!

	# shellcheck disable=SC2317
	finish() {
		kill "$NOTIFYPID"
		rm "$FIFO"
		exit 0
	}
	trap 'finish' TERM INT

	show
	# shellcheck disable=SC2034
	while read -r _; do
		show
	done < "$FIFO"
}

reset() {
	find "$ROOT" -mindepth 1 -delete
}

action="$1"
shift

case "$action" in
	""|"-s")
		show
		;;
	"-w")
		watch "$@"
		;;
	"-r")
		reset "$@"
		;;
	"-a")
		add "$@"
		;;
	"-d")
		del "$@"
		;;
	"-D")
		debug "$@"
		;;
	"-h")
		usage
		;;
esac
