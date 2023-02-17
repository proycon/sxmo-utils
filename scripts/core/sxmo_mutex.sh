#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

set -e

MUTEX_NAME="$1"
shift

ROOT_DIR="${XDG_RUNTIME_DIR:-/dev/shm/user/$(id -u)}"/sxmo_mutex
REASON_FILE="$ROOT_DIR/$MUTEX_NAME"
mkdir -p "$(dirname "$REASON_FILE")"
exec 3>"$REASON_FILE.lock"
touch "$REASON_FILE"

lock() {
	flock 3
	REASON="$1"
	printf "%s\n" "$REASON" >> "$REASON_FILE"
}

free() {
	flock 3
	REASON="$1"
	grep -xnm1 "$REASON" "$REASON_FILE" | \
		cut -d: -f1 | \
		xargs -r -I{} sed -i '{}d' "$REASON_FILE"
}

lockedby() {
	sxmo_debug "Lockedby: $1"
	grep -qxm1 "$1" "$REASON_FILE"
}

freeall() {
	printf "" > "$REASON_FILE"
	sxmo_hook_statusbar.sh lockedby
}

list() {
	cat "$REASON_FILE"
}

hold() {
	if ! [ -s "$REASON_FILE" ]; then
		exit 0
	fi

	FIFO="$(mktemp -u)"
	mkfifo "$FIFO"
	inotifywait -mq -e "close_write" "$ROOT_DIR" >> "$FIFO" &
	NOTIFYPID=$!

	# shellcheck disable=SC2317
	finish() {
		kill "$NOTIFYPID" 2>/dev/null
		rm "$FIFO"
		exit 0
	}
	trap 'finish' TERM INT EXIT

	# shellcheck disable=SC2034
	while read -r _; do
		if ! [ -s "$REASON_FILE" ]; then
			exit 0
		fi
	done < "$FIFO"
}

holdexec() {
	# shellcheck disable=SC2317
	finish() {
		kill "$HOLDPID" 2>/dev/null
		exit
	}
	trap 'finish' TERM INT

	hold &
	HOLDPID=$!
	wait "$HOLDPID"

	"$@"
}

"$@"
