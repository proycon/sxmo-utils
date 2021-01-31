#!/usr/bin/env sh

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
	lsof | grep "$WATCHFILE" && exit 0 # Already viewing watchfile, nops
	mkdir -p "$NOTIFDIR"
	if [ "$NOTIFFILEPATHTOWRITE" = "random" ]; then
		NOTIFFILEPATHTOWRITE="$NOTIFDIR/$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10)"
	fi
	touch "$NOTIFFILEPATHTOWRITE"
	printf %b "rm -f $NOTIFFILEPATHTOWRITE; $ACTION\n$WATCHFILE\n$NOTIFMSG\n" > "$NOTIFFILEPATHTOWRITE"
}

[ "$#" -lt 4 ] && echo "Need >=4 args to create a notification" && exit 1
writenotification
