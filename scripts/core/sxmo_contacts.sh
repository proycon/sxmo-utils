#!/usr/bin/env sh

# This script is a helper script for sxmo_modemtext.sh and sxmo_modemcall.sh
# When this script is called from a terminal, it prints the phone's known
# contacts in reverse chronological order of contact.

CONTACTSFILE="$XDG_CONFIG_HOME"/sxmo/contacts.tsv
LOGFILE="$XDG_CONFIG_HOME"/sxmo/modem/modemlog.tsv

SORTED_CONTACTS="$(mktemp)"
sort -k2 "$CONTACTSFILE" > "$SORTED_CONTACTS"

# Add names to numbers called/texted in modemlog
tab=$(printf '\t')
CALLED="$(sed 's/ +1//' "$LOGFILE" | sort -u -k3,3 |
	  join -t "$tab" -1 2 -2 3 -o 2.1,1.1,2.3 -a 2 "$SORTED_CONTACTS" - |
	  sort -rk1 | cut -f2,3 | sed 's/^\t//')"

# add all known contacts
ALL_DATA=$(printf %b "$CALLED\n$(cat "$CONTACTSFILE")" | nl)

## We must now remove contacts that have called/texted from the ALL_DATA list

# If there is a name for the contact, the row will have 3 columns
# if there is no name for the contact, the row will only have 2 columns.
# To make sure data lines up, remove contacts called and texted duplicate named contacts seperately
NAMED_ORDER="$(echo "$ALL_DATA" | awk 'NF==3{print}{}' | sort -uk3)"
NONAME="$(echo "$ALL_DATA" | awk 'NF==2{print}{}')"

RES=$(printf %b "$NAMED_ORDER\n$NONAME" | sort -k1 | cut -f2,3)

echo "$RES"
printf %b "$RES" | grep -q 8042221111 || echo "Test Number 8042221111"

rm "$SORTED_CONTACTS"