#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# Allow user to override what we log in the sms.txt file.  Note if you change
# this you probably should change sxmo_hook_tailtextlog.sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh
# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh

ACTION="$1" # recv or sent
LOGDIRNUM="$2" # The directory name in SXMO_LOG
NUM="$3" # The sender's phone number
TIME="$4"
TEXT="$5"
MMSID="$6" # optional

if [ "$ACTION" = "recv" ]; then
	VERB="Received"
else
	VERB="Sent"
fi

# if group chain also print the sender
if [ "$NUM" != "$LOGDIRNUM" ] && [ "$ACTION" = "recv" ]; then
	printf "%s from %s at %s:\n%b\n" \
		"$VERB" "$NUM" "$TIME" "$TEXT"
else
	printf "%s at %s:\n%b\n" \
		"$VERB" "$TIME" "$TEXT"
fi

# print any attachments
for attachment in "$SXMO_LOGDIR/$LOGDIRNUM/attachments/${MMSID}".*; do
	[ -f "$attachment" ] && printf "%s %s\n" "$icon_att" "$(basename "$attachment")"
done

printf "\n"
