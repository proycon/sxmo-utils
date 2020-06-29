#!/usr/bin/env sh
# This script prints in reverse chronological order unique entries from the
# modem log merged with contact names defined in contacts file tsv.
#   Wherein $CONTACTSFILE is tsv with two fields: number\tcontact name
#   Wherein $LOGFILE is *sorted* tsv with three fields: date\tevt\tnumber
# 
# Prints in output format: "number: contact"

CONTACTSFILE="$XDG_CONFIG_HOME"/sxmo/contacts.tsv
LOGFILE="$XDG_CONFIG_HOME"/sxmo/modem/modemlog.tsv

contacts() {
	RECENTCONTACTEDNUMBERSREVCHRON="$(
		cut -f3 "$LOGFILE" |
		tac |
		awk '!($0 in a){a[$0];print}' |
		sed '/^[[:space:]]*$/d'
	)"
	RECENTCONTACTEDNUMBERSREVCHRONF="$(mktemp)"
	echo "$RECENTCONTACTEDNUMBERSREVCHRON" > "$RECENTCONTACTEDNUMBERSREVCHRONF"
	printf %b "$(
		join -t"$(printf '\t')" -o1.1,2.2 -a1 -e"Unknown Number" \
		"$RECENTCONTACTEDNUMBERSREVCHRONF" "$CONTACTSFILE" |
		sed 's#\t#: #g'
	)"
	rm "$RECENTCONTACTEDNUMBERSREVCHRONF" &
}

contacts
