#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This hook displays the sms log for a numbers passed as $1

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

LOGDIRNUM="$1"
TERMNAME="$LOGDIRNUM SMS"
export TERMNAME

# If it's already open, switch to it.
if [ "$SXMO_WM" = "sway" ] && [ -z "$SSH_CLIENT" ]; then
	regesc_termname="$(echo "$TERMNAME" | sed 's|+|\\+|g')"
	swaymsg "[title=\"^$regesc_termname\$\"]" focus && exit 0
fi

mkcontactssedcmd() {
	pnc find "$LOGDIRNUM" | while read -r NUMBER; do
		CONTACT="$(sxmo_contacts.sh --name-or-number "$NUMBER")"
		if [ ! "$CONTACT" = "$NUMBER" ]; then
			printf %s "s/$NUMBER/$CONTACT/;"
		fi
	done
}

# Replace certain dates with human readable versions
TODAY="$(date +%F)"
YESTERDAY="$(date -d "- 1 day" +%F)"
TWO_DAYS="$(date -d "- 2 day" +%F)"
DATESEDCMD="s/at.*${TODAY}T/today at /; s/at.*${YESTERDAY}T/yesterday at /; s/at.*${TWO_DAYS}T/two days ago at /; s/-[0-9][0-9][0-9][0-9]://; s/\(-[0-9][0-9]\)T\([0-9][0-9]\)/\1 \2/;"

# TODO
#ALIGNSEDCMD="s/^Sent/<right align>/;s/^Received/<left align>/;"

# Colorize Sent and Received lines
RECEIVED_COLOR="2"
SENT_COLOR="3"
COLORSEDCMD="s#^\(Sent.*\)#$(tput setaf "$SENT_COLOR")\1$(tput op)#;s#^\(Received.*\)#$(tput setaf "$RECEIVED_COLOR")\1$(tput op)#;"

# Replace phone numbers in the filename with contacts from contact book
CONTACTSSEDCMD="$(mkcontactssedcmd)"

sxmo_terminal.sh sh -c "tail -n9999 -f \"$SXMO_LOGDIR/$LOGDIRNUM/sms.txt\" |\
	sed -e \"$CONTACTSSEDCMD\" -e \"$DATESEDCMD\" -e \"$COLORSEDCMD\""
#sxmo_terminal.sh sh -c "sxmo_hook_parselog.sh \"$NUMBER\""
