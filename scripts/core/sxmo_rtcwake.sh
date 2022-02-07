#!/bin/sh

# shellcheck source=configs/profile.d/sxmo_init.sh
. /etc/profile.d/sxmo_init.sh

# We can have multiple cronjobs at the same time
MUTEX_NAME=can_suspend sxmo_mutex.sh lock "Executing cronjob"
MUTEX_NAME=can_suspend sxmo_mutex.sh free "Waiting for cronjob"

finish() {
	MUTEX_NAME=can_suspend sxmo_mutex.sh free "Executing cronjob"
	exit 0
}

trap 'finish' TERM INT EXIT

echo "sxmo_rtcwake: Running sxmo_rtcwake for $* ($(date))" >&2
"$@"
