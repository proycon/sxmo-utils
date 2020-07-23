#!/usr/bin/env sh
LOGDIR="$XDG_CONFIG_HOME"/sxmo/modem
TERMMODE=$([ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] && echo "true")

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

sendmsg() {
	MODEM="$(modem_n)"
	NUMBER="$1"
	TEXT="$2"
	TEXTSIZE="${#TEXT}"

	SMSNO="$(
		mmcli -m "$MODEM" --messaging-create-sms="text='$TEXT',number=$NUMBER" |
		grep -o "[0-9]*$"
	)"
	mmcli -s "${SMSNO}" --send || err "Couldn't send text message"
	for i in $(mmcli -m "$MODEM" --messaging-list-sms | grep " (sent)" | cut -f5 -d' ') ; do
	  mmcli -m "$MODEM" --messaging-delete-sms="$i"
	done

	TIME="$(date --iso-8601=seconds)"
	mkdir -p "$LOGDIR/$NUMBER"
	printf %b "Sent to $NUMBER at $TIME:\n$TEXT\n\n" >> "$LOGDIR/$NUMBER/sms.txt"
	printf %b "$TIME\tsent_txt\t$NUMBER\t$TEXTSIZE chars\n" >> "$LOGDIR/modemlog.tsv"

	err "Sent text message ok"
}

sendtextmenu() {
	modem_n || err "Couldn't determine modem number - is modem online?"

	# Prompt for number
	NUMBER="$(
		printf %b "\nCancel\n$(sxmo_contacts.sh)" | 
		awk NF |
		menu sxmo_dmenu_with_kb.sh -p "Number" -fn "Terminus-20" -l 10 -c -i |
		cut -d: -f1 |
		tr -d -- '-+ '
	)"
	echo "$NUMBER" | grep -E "^Cancel$" && exit 1
	echo "$NUMBER" | grep -qE '^[+0-9]+$' || err "That doesn't seem like a valid number"

	# Compose first version of msg
	TEXT="$(editmsg "$NUMBER" 'Enter text message here')"

	while true
	do
		CONFIRM="$(
			printf %b "Edit Message ($TEXT)\nSend to → $NUMBER\nCancel" |
			menu dmenu -c -idx 1 -p "Confirm" -fn "Terminus-20" -l 10
		)"
		echo "$CONFIRM" | grep -E "^Send" && sendmsg "$NUMBER" "$TEXT" && exit 0
		echo "$CONFIRM" | grep -E "^Cancel$" && exit 1
		echo "$CONFIRM" | grep -E "^Edit Message" && TEXT="$(editmsg "$NUMBER" "$TEXT")"
	done
}

tailtextlog() {
	if [ "$TERMMODE" != "true" ]; then
		st -e tail -n9999 -f "$LOGDIR/$1/sms.txt"
	else
		tail -n9999 -f "$LOGDIR/$1/sms.txt"
	fi
}

main() {
	# E.g. only display logfiles for directories that exist and join w contact name
	ENTRIES="$(
		printf %b "Close Menu\nSend a Text\n";
		# shellcheck disable=SC2045
		for TDIR in $(ls -1 -t "$LOGDIR"); do
			[ -d "$LOGDIR"/"$TDIR" ] || continue
			NUM="$(basename "$TDIR")"
			sxmo_contacts.sh | grep -m1 "$NUM" | xargs -IL echo "L logfile"
		done
	)"
	CONTACTIDANDNUM="$(printf %b "$ENTRIES" | menu dmenu -p Texts -c -fn Terminus-20 -l 10 -i)"
	echo "$CONTACTIDANDNUM" | grep "Close Menu" && exit 1
	echo "$CONTACTIDANDNUM" | grep "Send a Text" && sendtextmenu && exit 1
	tailtextlog "$(echo "$CONTACTIDANDNUM" | cut -d: -f1)"
}

main
