#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

transition() {
	sxmo_log "transitioning to stage $state"
	printf %s "$state" > "$SXMO_STATE"

	sxmo_hook_"$state".sh &
	sxmo_hook_statusbar.sh state_change &
	wait
}

up() {
	count="${1:-1}"
	while [ "$count" -gt 0 ]; do
		case "$state" in
			unlock)
				state=screenoff
				;;
			screenoff)
				state=lock
				;;
			lock)
				state=unlock
				;;
		esac
		count=$((count-1))
	done
	transition
}

down() {
	count="${1:-1}"
	while [ "$count" -gt 0 ]; do
		case "$state" in
			unlock)
				state=lock
				;;
			screenoff)
				state=unlock
				;;
			lock)
				state=screenoff
				;;
		esac
		count=$((count-1))
	done
	transition
}

exec 3<> "$SXMO_STATE.lock"
flock -x 3

state="$(cat "$SXMO_STATE")"

action="$1"
shift
case "$action" in
	up)
		up "$@"
		;;
	down)
		down "$@"
		;;
	set)
		case "$1" in
			lock|unlock|screenoff)
				state="$1"
				transition
				;;
		esac
		;;
esac
