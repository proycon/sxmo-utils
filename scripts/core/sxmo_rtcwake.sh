#!/bin/sh

# shellcheck source=configs/profile.d/sxmo_init.sh
. /etc/profile.d/sxmo_init.sh

# We can have multiple cronjobs at the same time
sxmo_mutex.sh can_suspend lock "Executing cronjob"
sxmo_mutex.sh can_suspend free "Waiting for cronjob"

finish() {
	sxmo_mutex.sh can_suspend free "Executing cronjob"
	exit 0
}

trap 'finish' TERM INT EXIT

echo "sxmo_rtcwake: Running sxmo_rtcwake for $* ($(date))" >&2
"$@"
