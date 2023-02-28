#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors
# This script prints in reverse chronological order unique entries from the
# modem log merged with contact names defined in contacts file tsv.
#   Wherein $SXMO_CONTACTFILE is tsv with two fields: number\tcontact name
#   Wherein $LOGFILE is *sorted* tsv with three fields: date\tevt\tnumber
#
#   Most normal numbers should be a full phone number starting with + and the country number
#   Some special numbers (ie. 2222, "CR AGRICOLE") can ignore this pattern
#
# Prints in output format: "number: contact"

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

LOGFILE="$SXMO_LOGDIR"/modemlog.tsv

prepare_contacts_list() {
	cut -f3 |
	tac |
	awk '!($0 in a){a[$0]; print}' |
	sed '/^[[:space:]]*$/d' |
	awk -F '\t' -v SXMO_CONTACTFILE="$SXMO_CONTACTFILE" '
		function join(array, sep) {
			result = ""
			cs = ""

			for (i in array) {
				if (length(result)) cs = sep;
				result = result cs array[i]
			}

			return result
		}

		function name_for_num(num) {
			if (!a[num]) a[num] = "???";
			return a[num]
		}

		FILENAME == SXMO_CONTACTFILE {
			if (!length()) next;
			a[$1] = $2;
			next
		}

		# Multiple numbers, unknown group name
		/(\+[^+]+){2,}/ && !a[$1] {
			split("", names) # empty the names array
			split($1, nums, "+")

			for (i in nums) {
				num = nums[i]
				if (length(num) == 0) continue;

				names[i] = name_for_num("+" num)
			}

			print join(names, ", ") ": " $0
			next
		}

		{
			print name_for_num($1) ": " $0
		}
	' "$SXMO_CONTACTFILE" -
}

contacts() {
	prepare_contacts_list < "$LOGFILE"
}

texted_contacts() {
	grep "\(recv\|sent\)_\(txt\|mms\|vvm\)" "$LOGFILE" | prepare_contacts_list
}

called_contacts() {
	grep "call_\(pickup\|start\)" "$LOGFILE" | prepare_contacts_list
}

all_contacts() {
	awk -F'\t' '{
		print $2 ": " $1
	}' "$SXMO_CONTACTFILE" | sort -f -k 1
}

unknown_contacts() {
	contacts \
		| grep "^???" \
		| cut -d: -f2 \
		| grep "^ +[0-9]\{9,14\}" \
		| sed 's/^ //'
}

[ -f "$SXMO_CONTACTFILE" ] || touch "$SXMO_CONTACTFILE"

if [ "$1" = "--all" ]; then
	all_contacts
elif [ "$1" = "--unknown" ]; then
	unknown_contacts
elif [ "$1" = "--texted" ]; then
	texted_contacts
elif [ "$1" = "--called" ]; then
	called_contacts
elif [ "$1" = "--me" ]; then
	all_contacts \
		| grep "^Me: " \
		| sed 's|^Me: ||'
elif [ "$1" = "--name-or-number" ]; then
	if [ -z "$2" ]; then
		printf "???\n"
	else
		contact="$(sxmo_contacts.sh --name "$2")"
		[ "$contact" = "???" ] && contact="$2"
		printf %s "$contact"
	fi
elif [ "$1" = "--name" ]; then
	if [ -z "$2" ]; then
		printf "???\n"
	else
		all_contacts \
			| xargs -0 printf "???: %s\n%b" "$2" \
			| tac \
			| grep -m1 ": $2$" \
			| sed -e 's/\(.*\):\(.*\)/\1/' -e 's/^[ \t]*//;s/[ \t]*$//'
	fi
elif [ -n "$*" ]; then
	all_contacts | grep -i "$*"
else
	contacts
fi
