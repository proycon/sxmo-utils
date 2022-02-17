#!/bin/sh

# This hook displays the sms log for a numbers passed as $1

. sxmo_common.sh
NUMBER="$1"
CONTACTNAME="$(sxmo_contacts.sh | grep ": ${NUMBER}$" | cut -d: -f1)"
[ "???" = "$CONTACTNAME" ] && CONTACTNAME="$CONTACTNAME ($NUMBER)"

TERMNAME="$NUMBER SMS" sxmo_terminal.sh sh -c "tail -n9999 -f \"$SXMO_LOGDIR/$NUMBER/sms.txt\" | sed \"s|$NUMBER|$CONTACTNAME|g\""


