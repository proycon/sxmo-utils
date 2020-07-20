#!/usr/bin/env sh
# This script prints in reverse chronological order unique entries from the
# modem log merged with contact names defined in contacts file tsv.
#   Wherein $CONTACTSFILE is tsv with two fields: number\tcontact name
#   Wherein $LOGFILE is *sorted* tsv with three fields: date\tevt\tnumber
#   number should be a full phone number starting with + and the country number
#
# Prints in output format: "number: contact"

CONTACTSFILE="$XDG_CONFIG_HOME"/sxmo/contacts.tsv
LOGFILE="$XDG_CONFIG_HOME"/sxmo/modem/modemlog.tsv

contacts() {
	grep -q . "$CONTACTSFILE" || echo " " > "$CONTACTSFILE"
	RECENTCONTACTEDNUMBERSREVCHRON="$(
		cut -f3 "$LOGFILE" |
		tac |
		awk '!($0 in a){a[$0]; if (substr($0,1,1) == "+") print}' |
		sed '/^[[:space:]]*$/d'
	)"
	printf %b "$RECENTCONTACTEDNUMBERSREVCHRON" | awk -F'\t' '
		FNR==NR{a[$1]=$2; next}
		{
			if (!a[$1]) a[$1] = "Unknown Number";
			if (substr($0,1,1) == "+") print $0 ": " a[$1]
		}
	' "$CONTACTSFILE" -
}

contacts
