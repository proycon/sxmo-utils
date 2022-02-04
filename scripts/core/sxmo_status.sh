#!/bin/sh

# A pretty generic status content generator
# It aggregate all file content present in a folder
# It sort file elements numerically
# It can watch file events to stdout new content

ROOT="${XDG_RUNTIME_DIR:-$HOME/.local/run}/sxmo_status/${SXMO_STATUS_NAME:-default}"
mkdir -p "$ROOT"

_sorted_components_name() {
	find "$ROOT" -exec 'basename' '{}' ';' -mindepth 1 | sort -n
}

usage() {
	printf "Usage: %s [ACTIONS]\n" "$(basename "$0")" >&2
	printf "ACTIONS:\n" >&2
	printf "	show: the status content (default action)\n" >&2
	printf "	watch: file events and stdout status content\n" >&2
	printf "	add <id> <content>: add a bar component\n" >&2
	printf "	add <id>: add a bar component from stdin\n" >&2
	printf "	del <id>: remove a bar component\n" >&2
	printf "	reset: remove all bar components\n" >&2
	printf "	debug: the status content explained\n" >&2
	printf "	help: this message\n" >&2
}

add() {
	id="$1"
	shift

	if [ -z "$id" ]; then
		printf "usage: %s add <id>\n" "$(basename "$0")" >&2
		exit 1
	fi

	if [ -z "$*" ]; then
		value="$(cat)"
	else
		value="$*"
	fi

	if [ -n "$value" ]; then
		printf "%s" "$value" > "$ROOT"/"$id"
	else
		rm -f "$ROOT"/"$id"
	fi
}

del() {
	id="$1"
	shift

	if [ -z "$id" ]; then
		printf "usage: %s rm <id>\n" "$(basename "$0")" >&2
		exit 1
	fi

	rm -f "$ROOT"/"$id"
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

	finish() {
		kill "$NOTIFYPID"
		rm "$FIFO"
		exit 0
	}
	trap 'finish' TERM INT

	show
	while read -r; do
		show
	done < "$FIFO"
}

reset() {
	find "$ROOT" -delete -mindepth 1
}

case "$1" in
	"")
		show
		;;
	show|watch|reset|add|del|debug)
		"$@"
		;;
	*)
		usage
		;;
esac
