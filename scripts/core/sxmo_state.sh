#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

SXMO_STATE="${SXMO_STATE:-$XDG_RUNTIME_DIR/sxmo.state}"
if command -v peanutbutter 2> /dev/null; then
	#no separate lock stage needed when peanutbutter is used
	SXMO_STATES="${SXMO_STATES:-unlock screenoff}"
else
	SXMO_STATES="${SXMO_STATES:-unlock lock screenoff}"
fi
SXMO_SUSPENDABLE_STATES="${SXMO_SUSPENDABLE_STATES:-screenoff 3}"

transition_can_suspend() {
	# shellcheck disable=SC2086
	set -- $SXMO_SUSPENDABLE_STATES

	tmpstate=
	timeout=
	while [ $# -gt 0 ]; do
		if [ "$1" = "$state" ]; then
			tmpstate="$1"
			timeout="$2"
			break
		fi
		shift 2
	done

	stop_idle_suspender() {
		sxmo_jobs.sh stop idle_suspender
		sxmo_wakelock.sh lock sxmo_not_suspendable infinite
	}

	if [ -z "$tmpstate" ]; then
		sxmo_log "this state is not suspendable"
		stop_idle_suspender
		return
	fi

	if ! printf "%b\n" "$timeout" | grep -q '^[0-9]\+$'; then
		sxmo_log "there is no valid suspendable timeout for this state"
		stop_idle_suspender
		return
	fi

	sxmo_log "idle suspender started with timeout $timeout"
	sxmo_jobs.sh start idle_suspender sxmo_idle.sh -w \
		timeout "$timeout" 'sxmo_wakelock.sh unlock sxmo_not_suspendable' \
		resume 'sxmo_wakelock.sh lock sxmo_not_suspendable infinite'
}

transition() {
	state="$1"

	sxmo_log "transitioning to stage $state"
	printf %s "$state" > "$SXMO_STATE"

	lock_shared

	(
		# We need a subshell so we can close the lock fd, without
		# releasing the lock
		exec 3<&-

		sxmo_hook_"$state".sh &
		sxmo_hook_statusbar.sh state_change &
		transition_can_suspend &

		wait
	)
}

click() {
	count="${1:-1}"
	# shellcheck disable=SC2086
	set -- $SXMO_STATES
	i=1
	while [ $i -le $# ]; do
		tmpstate=
		prevstate=
		eval "tmpstate=\$$i"
		if [ "$tmpstate" = "$state" ]; then
			if [ $i = 1 ]; then
				eval "prevstate=\$$#"
			else
				eval "prevstate=\$$((i-1))"
			fi
			state="$prevstate"
			break
		fi
		i=$((i+1))
	done
	if [ "$count" -gt 1 ]; then
		click $((count-1))
	else
		transition "$state"
	fi
	flushstored
}

idle() {
	count="${1:-1}"
	# shellcheck disable=SC2086
	set -- $SXMO_STATES
	while [ $# -gt 1 ]; do
		if [ "$1" = "$state" ]; then
			if [ "$count" -ge "$#" ]; then
				count=$(($# - 1))
			fi
			shift "$count"
			transition "$1"
			return
		fi
		shift
	done

	sxmo_log "idle: not transitioning from $state"
}

store() {
	storeid="$(tr -dc 'a-zA-Z0-9' < /dev/urandom 2>/dev/null | head -c 10)"
	printf %s "$state" > "$SXMO_STATE.stored.$storeid"
	printf %s "$storeid"
}

flushstored() {
	find "$(dirname "$SXMO_STATE")" -name 'sxmo.state.stored.*' -delete
}

restore() {
	storeid="$1"
	if [ -f "$SXMO_STATE.stored.$storeid" ]; then
		state="$(cat "$SXMO_STATE.stored.$storeid")"
		transition "$state"
		flushstored
	fi
}

exec 3<> "$SXMO_STATE.lock"

lock_exclusive() {
	flock -x 3
}

lock_shared() {
	flock -s 3
}

read_state() {
	state="$(cat "$SXMO_STATE")"
}

action="$1"
shift
case "$action" in
	click|idle)
		lock_exclusive
		read_state
		"$action" "$@" ;;
	get)
		lock_shared
		read_state
		printf %s "$state"
		;;
	set)
		lock_exclusive
		read_state
		if printf "%b\n" "$SXMO_STATES" | tr ' ' '\n' | grep -xq "$1"; then
			transition "$1"
		fi
		;;
	store)
		lock_exclusive
		read_state
		store
		;;
	restore)
		lock_exclusive
		restore "$1"
		;;
	flushstored)
		lock_exclusive
		flushstored
		;;
esac
