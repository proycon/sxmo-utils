#!/usr/bin/env sh
# This script prints in reverse chronological order unique entries from the
# modem log merged with contact names defined in contacts file tsv.
#   Wherein $CONTACTSFILE is tsv with two fields: number\tcontact name
#   Wherein $LOGFILE is *sorted* tsv with three fields: date\tevt\tnumber
#
#   Most normal numbers should be a full phone number starting with + and the country number
#   Some special numbers (ie. 2222, "CR AGRICOLE") can ignore this pattern
#
# Prints in output format: "number: contact"

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

CONTACTSFILE="$XDG_CONFIG_HOME"/sxmo/contacts.tsv
LOGFILE="$XDG_DATA_HOME"/sxmo/modem/modemlog.tsv

prepare_contacts_list() {
	cut -f3 |
	tac |
	awk '!($0 in a){a[$0]; print}' |
	sed '/^[[:space:]]*$/d' |
	awk -F'\t' '
		FNR==NR{a[$1]=$2; next}
		{
			if (!a[$1]) a[$1] = "Unknown Number";
			print $0 ": " a[$1]
		}
	' "$CONTACTSFILE" -
}

contacts() {
	prepare_contacts_list < "$LOGFILE"
}

texted_contacts() {
	grep "\(recv\|sent\)_txt" "$LOGFILE" | prepare_contacts_list
}

called_contacts() {
	grep "call_\(pickup\|start\)" "$LOGFILE" | prepare_contacts_list
}

all_contacts() {
	awk -F'\t' '{
		print $1 ": " $2
	}' "$CONTACTSFILE" | sort -f -k 2
}

unknown_contacts() {
	contacts \
		| grep "Unknown Number$" \
		| cut -d: -f1 \
		| grep "^+[0-9]\{9,14\}$"
}

[ -f "$CONTACTSFILE" ] || touch "$CONTACTSFILE"

if [ "$1" = "--all" ]; then
	all_contacts
elif [ "$1" = "--unknown" ]; then
	unknown_contacts
elif [ "$1" = "--texted" ]; then
	texted_contacts
elif [ "$1" = "--called" ]; then
	called_contacts
else
	contacts
fi
