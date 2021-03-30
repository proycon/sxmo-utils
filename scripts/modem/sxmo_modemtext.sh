#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

TERMMODE=$([ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] && echo "true")
DRAFT_DIR="$XDG_DATA_HOME/sxmo/modem/draft"

menu() {
	if [ "$TERMMODE" != "true" ]; then
		"$@"
	else
		vis-menu -i -l 10
	fi
}

err() {
	echo "$1">&2
	echo "$1" | menu dmenu -c -l 10
	kill $$
}

modem_n() {
	MODEMS="$(mmcli -L)"
	echo "$MODEMS" | grep -qoE 'Modem\/([0-9]+)' || err "Couldn't find modem - is your modem enabled?"
	echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
}

editmsg() {
	TMP="$(mktemp --suffix "$1_msg")"
	echo "$2" > "$TMP"
	if [ "$TERMMODE" != "true" ]; then
		st -e "$EDITOR" "$TMP"
	else
		"$EDITOR" "$TMP"
	fi
	cat "$TMP"
}

choosenumbermenu() {
	modem_n >/dev/null || err "Couldn't determine modem number - is modem online?"

	# Prompt for number
	NUMBER="$(
		printf %b "\n$icon_cls Cancel\n$icon_grp More contacts\n$(sxmo_contacts.sh | grep -E "^\+?[0-9]+:")" |
		awk NF |
		menu sxmo_dmenu_with_kb.sh -p "Number" -l 10 -c -i |
		cut -d: -f1 |
		tr -d -- '- '
	)"
	echo "$NUMBER" | grep -q "Morecontacts" && NUMBER="$( #joined words without space is not a bug
		printf %b "\nCancel\n$(sxmo_contacts.sh --all)" |
			grep . |
			menu sxmo_dmenu_with_kb.sh -l 10 -p "Number" -c -i |
			cut -d: -f1 |
			tr -d -- '- '
	)"
	echo "$NUMBER" | grep -q "Cancel" && exit 1
	echo "$NUMBER" | grep -qE '^[+0-9]+$' || err "That doesn't seem like a valid number"
	echo "$NUMBER"
}

sendnewtextmenu() {
	NUMBER="$(choosenumbermenu)"
	# Compose first version of msg
	TEXT="$(editmsg "$NUMBER" 'Enter text message here')"
	sendtextmenu "$NUMBER" "$TEXT"
}

sendtextmenu() {
	NUMBER="$1"
	TEXT="$2"
	while true
	do
		CONFIRM="$(
			printf %b "$icon_edt Edit Message ($(echo "$TEXT" | head -n1))\n$icon_snd Send to → $NUMBER\n$icon_sav Save as Draft\n$icon_cls Cancel" |
			menu dmenu -c -idx 1 -p "Confirm" -l 10
		)"
		echo "$CONFIRM" | grep -E "Send to" && (echo "$TEXT" | sxmo_modemsendsms.sh "$NUMBER" -) && echo "Sent text to $NUMBER">&2 && exit 0
		echo "$CONFIRM" | grep -E "Cancel$" && exit 1
		echo "$CONFIRM" | grep -E "Edit Message" && TEXT="$(editmsg "$NUMBER" "$TEXT")"
		echo "$CONFIRM" | grep -E "Save as Draft$" && err "Draft saved to $(draft "$NUMBER" "$TEXT")"
	done
}

draft() {
	NUMBER="$1"
	TEXT="$2"
	DRAFT_FILE="$NUMBER-$(date +'%Y-%m-%d_%H-%m-%S')"
	echo "$NUMBER" > "$DRAFT_DIR/$DRAFT_FILE"
	echo "$TEXT" >> "$DRAFT_DIR/$DRAFT_FILE"
	echo "$DRAFT_FILE"
}

senddrafttextmenu() {
	CONFIRM="$(
		printf %b "$icon_cls Cancel\n$(ls "$DRAFT_DIR")" |
		menu sxmo_dmenu_with_kb.sh -p "Draft Message" -l 10 -c -i
	)"
	echo "$CONFIRM" | grep -E "Cancel$" && exit 1
	FILE="$DRAFT_DIR/$CONFIRM"
	NUMBER="$(head -n1 "$FILE")"
	TEXT="$(tail -n +2 "$FILE")"
	rm "$FILE"
	sendtextmenu "$NUMBER" "$TEXT"
}

tailtextlog() {
	if [ "$TERMMODE" != "true" ]; then
		st -T "$1 SMS" -e tail -n9999 -f "$LOGDIR/$1/sms.txt"
	else
		tail -n9999 -f "$LOGDIR/$1/sms.txt"
	fi
}

main() {
	[ ! -d "$DRAFT_DIR" ] && mkdir -p "$DRAFT_DIR"
	# E.g. only display logfiles for directories that exist and join w contact name
	ENTRIES="$(
	printf %b "$icon_cls Close Menu\n$icon_edt Send a Text$( [ "$(ls -A "$DRAFT_DIR")" ] && printf %b "\n$icon_edt Send a Draft Text")\n";
		sxmo_contacts.sh | while read -r CONTACT; do
			[ -d "$LOGDIR"/"$(printf %b "$CONTACT" | cut -d: -f1)" ] || continue
			printf %b "$CONTACT" | xargs -IL echo "L logfile"
		done
	)"
	CONTACTIDANDNUM="$(printf %b "$ENTRIES" | menu dmenu -p Texts -c -l 10 -i)"
	echo "$CONTACTIDANDNUM" | grep "Close Menu" && exit 1
	echo "$CONTACTIDANDNUM" | grep "Send a Text" && sendnewtextmenu && exit 1
	echo "$CONTACTIDANDNUM" | grep "Send a Draft Text" && senddrafttextmenu && exit 1
	tailtextlog "$(echo "$CONTACTIDANDNUM" | cut -d: -f1)"
}

if [ -n "$1" ]; then
	sendnewtextmenu "$1"
else
	main
fi
