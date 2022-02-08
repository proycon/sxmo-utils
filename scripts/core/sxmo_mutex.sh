#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(which sxmo_common.sh)"

set -e

MUTEX_NAME="${MUTEX_NAME:-default}"
ROOT_DIR="${XDG_RUNTIME_DIR:-$HOME/.local/run}/sxmo_mutex"
REASON_FILE="$ROOT_DIR/$MUTEX_NAME"
mkdir -p "$(dirname "$REASON_FILE")"
touch "$REASON_FILE"

lock() {
	printf "%s\n" "$1" >> "$REASON_FILE"
}

free() {
	grep -xnm1 "$1" "$REASON_FILE" | \
		cut -d: -f1 | \
		xargs -rn1 -I{} sed -i '{}d' "$REASON_FILE"
}

lockedby() {
	grep -qxm1 "$1" "$REASON_FILE"
}

freeall() {
	printf "" > "$REASON_FILE"
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

	finish() {
		kill "$NOTIFYPID"
		rm "$FIFO"
		exit 0
	}
	trap 'finish' TERM INT EXIT

	while read -r; do
		if ! [ -s "$REASON_FILE" ]; then
			exit 0
		fi
	done < "$FIFO"
}

holdexec() {
	finish() {
		kill "$HOLDPID"
		exit
	}
	trap 'finish' TERM INT

	hold &
	HOLDPID=$!
	wait "$HOLDPID"

	"$@"
}

"$@"
