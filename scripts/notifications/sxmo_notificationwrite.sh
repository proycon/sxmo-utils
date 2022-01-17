#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

# Takes 4 args:
# (1) the filepath of the notification to write (or random to generate a random id)
# (2) action notification invokes upon selecting
# (3) the file to watch for deactivation.
# (4) description of notification
NOTIFFILEPATHTOWRITE="$1"
ACTION="$2"
WATCHFILE="$3"
NOTIFMSG="$4"

writenotification() {
	mkdir -p "$NOTIFDIR"
	if [ "$NOTIFFILEPATHTOWRITE" = "random" ]; then
		NOTIFRANDOM="$(tr -dc 'a-zA-Z0-9' < /dev/urandom 2>/dev/null | head -c 10)"
		NOTIFFILEPATHTOWRITE="$NOTIFDIR/$NOTIFRANDOM"
	fi
	touch "$NOTIFFILEPATHTOWRITE"
	printf "%s\n%s\n%b\n" \
		"$ACTION" "$WATCHFILE" "$NOTIFMSG" \
		> "$NOTIFFILEPATHTOWRITE"
}

[ "$#" -lt 4 ] && echo "Need >=4 args to create a notification" && exit 1
writenotification

if sxmo_screenlock.sh getCurState | grep -q off; then
	sxmo_screenlock.sh lock
fi
