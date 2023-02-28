#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# Allow user to override what we log in the sms.txt file.

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh
# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh

VERB="$1" # Received or Sent
TYPE="$2" # SMS, MMS, or GroupMMS
NUM="$3"  # if GroupMMS this will be "FromNumber ToNumbers LogdirNumber"
TIME="$4"
TEXT="$5"
MMSID="$6" # optional

basiclogging() {
	if [ "$VERB" = "Received" ]; then
		PREPOSITION="from"
	else
		PREPOSITION="to"
	fi

	if [ "$TYPE" = "GroupMMS" ]; then
		# who sent it
		FROM_NUM="$(printf "%s" "$NUM" | cut -d' ' -f1)"
		# who else did they send it to
		TO_NUMS="$(printf "%s" "$NUM" | cut -d' ' -f2)"
		# what is the actual logdir number (will be everyone's phone number except yours)
		NUM="$(printf "%s" "$NUM" | cut -d' ' -f3)"

		printf "%s %s %s %s (to: %s) at %s:\n%s\n" \
			"$VERB" "$TYPE" "$PREPOSITION" "$FROM_NUM" "$TO_NUMS" "$TIME" "$TEXT"
	else
		printf "%s %s %s %s at %s:\n%s\n" \
			"$VERB" "$TYPE" "$PREPOSITION" "$NUM" "$TIME" "$TEXT"
	fi

	if [ -f "$SXMO_LOGDIR/$NUM/attachments/$MMS_ID.attachments.txt" ]; then
		cat "$SXMO_LOGDIR/$NUM/attachments/$MMS_ID.attachments.txt" | tr '\n' '\0' | xargs -0 printf "$icon_att %s\n"
	fi

	printf "\n"
}

generate_to_list() {
	pnc find "$1" | while read -r line; do
		printf "%s, " "$(sxmo_contacts.sh --name-or-number "$line")"
	done
}

fancylogging() {
	if [ "$VERB" = "Received" ]; then
		PREPOSITION="from"
	else
		PREPOSITION="to"
	fi

	PRETTY_TIME="$(date -d "$TIME")"

	if [ "$TYPE" = "GroupMMS" ]; then
		# who sent it
		FROM_NUM="$(printf "%s" "$NUM" | cut -d' ' -f1)"
		# who else did they send it to
		TO_NUMS="$(printf "%s" "$NUM" | cut -d' ' -f2)"
		# everyone except you
		NUM="$(printf "%s" "$NUM" | cut -d' ' -f3)"

		FROM_CONTACT="$(sxmo_contacts.sh --name-or-number "$FROM_NUM")"

		TO_CONTACTS="$(generate_to_list "$TO_NUMS" | sed 's/, $//')"
		generate_to_list | sed 's/, $//'

		#This would be the contact for the entire group chain, if any.
		NUM_CONTACT="$(sxmo_contacts.sh --name "$NUM")"

		printf "%s\n%s %s (%s)\nFrom: %s\nTo: %s\n%s\n" \
			"$PRETTY_TIME" \
			"$VERB" \
			"$TYPE" \
			"$NUM_CONTACT" \
			"$FROM_CONTACT" \
			"$TO_CONTACTS" \
			"$TEXT"
	else
		FROM_CONTACT="$(sxmo_contacts.sh --name-or-number "$NUM")"

		printf "%s\n%s %s %s %s:\n%s\n" \
			"$PRETTY_TIME" \
			"$VERB" \
			"$TYPE" \
			"$PREPOSITION" \
			"$FROM_CONTACT" \
			"$TEXT"
	fi

	if [ -f "$SXMO_LOGDIR/$LOGDIR_NUM/attachments/$MMS_ID.attachments.txt" ]; then
		tr '\n' '\0' < "$SXMO_LOGDIR/$LOGDIR_NUM/attachments/$MMS_ID.attachments.txt" \
			| xargs -0 printf "$icon_att %s\n"
	fi

	printf "\n"
}

#basiclogging "$@"

fancylogging "$@"
