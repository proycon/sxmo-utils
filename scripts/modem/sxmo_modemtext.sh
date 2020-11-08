#!/usr/bin/env sh
LOGDIR="$XDG_DATA_HOME"/sxmo/modem
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
	echo "$1" | menu dmenu -fn Terminus-20 -c -l 10
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
		printf %b "\nCancel\nMore contacts\n$(sxmo_contacts.sh)" |
		awk NF |
		menu sxmo_dmenu_with_kb.sh -p "Number" -fn "Terminus-20" -l 10 -c -i |
		cut -d: -f1 |
		tr -d -- '- '
	)"
	echo "$NUMBER" | grep -qE "^Morecontacts$" && NUMBER="$( #joined words without space is not a bug
		printf %b "\nCancel\n$(sxmo_contacts.sh --all)" |
			grep . |
			menu sxmo_dmenu_with_kb.sh -l 10 -p "Number" -c -fn Terminus-20 -i |
			cut -d: -f1 |
			tr -d -- '- '
	)"
	echo "$NUMBER" | grep -qE "^Cancel$" && exit 1
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
			printf %b "Edit Message ($(echo "$TEXT" | head -n1))\nSend to → $NUMBER\nSave as Draft\nCancel" |
			menu dmenu -c -idx 1 -p "Confirm" -fn "Terminus-20" -l 10
		)"
		echo "$CONFIRM" | grep -E "^Send" && (echo "$TEXT" | sxmo_modemsendsms.sh "$NUMBER" -) && exit 0
		echo "$CONFIRM" | grep -E "^Cancel$" && exit 1
		echo "$CONFIRM" | grep -E "^Edit Message" && TEXT="$(editmsg "$NUMBER" "$TEXT")"
		echo "$CONFIRM" | grep -E "^Save as Draft$" && err "Draft saved to $(draft "$NUMBER" "$TEXT")"
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
		printf %b "Cancel\n$(ls "$DRAFT_DIR")" |
		menu sxmo_dmenu_with_kb.sh -p "Draft Message" -fn "Terminus-20" -l 10 -c -i
	)"
	echo "$CONFIRM" | grep -E "^Cancel$" && exit 1
	FILE="$DRAFT_DIR/$CONFIRM"
	NUMBER="$(head -n1 "$FILE")"
	TEXT="$(tail -n +2 "$FILE")"
	rm "$FILE"
	sendtextmenu "$NUMBER" "$TEXT"
}

tailtextlog() {
	if [ "$TERMMODE" != "true" ]; then
		st -e tail -n9999 -f "$LOGDIR/$1/sms.txt"
	else
		tail -n9999 -f "$LOGDIR/$1/sms.txt"
	fi
}

main() {
	[ ! -d "$DRAFT_DIR" ] && mkdir -p "$DRAFT_DIR"
	# E.g. only display logfiles for directories that exist and join w contact name
	ENTRIES="$(
	printf %b "Close Menu\nSend a Text$( [ "$(ls -A "$DRAFT_DIR")" ] && printf %b "\nSend a Draft Text")\n";
		sxmo_contacts.sh | while read -r CONTACT; do
			[ -d "$LOGDIR"/"$(printf %b "$CONTACT" | cut -d: -f1)" ] || continue
			printf %b "$CONTACT" | xargs -IL echo "L logfile"
		done
	)"
	CONTACTIDANDNUM="$(printf %b "$ENTRIES" | menu dmenu -p Texts -c -fn Terminus-20 -l 10 -i)"
	echo "$CONTACTIDANDNUM" | grep "Close Menu" && exit 1
	echo "$CONTACTIDANDNUM" | grep "Send a Text" && sendnewtextmenu && exit 1
	echo "$CONTACTIDANDNUM" | grep "Send a Draft Text" && senddrafttextmenu && exit 1
	tailtextlog "$(echo "$CONTACTIDANDNUM" | cut -d: -f1)"
}

main
