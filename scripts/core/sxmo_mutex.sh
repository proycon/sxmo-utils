#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

set -e

MUTEX_NAME="$1"
shift

ROOT_DIR="${XDG_RUNTIME_DIR:-$HOME/.local/run}/sxmo_mutex"
REASON_FILE="$ROOT_DIR/$MUTEX_NAME"
mkdir -p "$(dirname "$REASON_FILE")"
touch "$REASON_FILE"

lock() {
	# shellcheck disable=SC2016
	flock "$REASON_FILE" env "REASON=$1" "REASON_FILE=$REASON_FILE" sh -c '
		printf "%s\n" "$REASON" >> "$REASON_FILE"
	' # flock drops the lock when the program it's running finishes
}

free() {
	# shellcheck disable=SC2016
	flock "$REASON_FILE" env "REASON=$1" "REASON_FILE=$REASON_FILE" sh -c '
		grep -xnm1 "$REASON" "$REASON_FILE" | \
			cut -d: -f1 | \
			xargs -r -I{} sed -i '{}d' "$REASON_FILE"
	' # flock drops the lock when the program it's running finishes
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
