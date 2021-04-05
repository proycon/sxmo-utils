#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

TERMMODE=$([ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] && echo "true")

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

choosenumbermenu() {
	# Prompt for number
	NUMBER="$(
		printf %b "\n$icon_cls Cancel\n$icon_grp More contacts\n$(sxmo_contacts.sh | grep -E "^\+?[0-9]+:")" |
		awk NF |
		menu sxmo_dmenu_with_kb.sh -p "Number" -l 10 -c -i |
		cut -d: -f1 |
		tr -d -- '- '
	)"
	if echo "$NUMBER" | grep -q "Morecontacts"; then
		NUMBER="$( #joined words without space is not a bug
			printf %b "\nCancel\n$(sxmo_contacts.sh --all)" |
				grep . |
				menu sxmo_dmenu_with_kb.sh -l 10 -p "Number" -c -i |
				cut -d: -f1 |
				tr -d -- '- '
		)"
	fi

	if echo "$NUMBER" | grep -q "Cancel"; then
		exit 1
	elif ! echo "$NUMBER" | grep -qE '^[+0-9]+$'; then
		notify-send "That doesn't seem like a valid number"
	else
		echo "$NUMBER"
	fi
}

sendtextmenu() {
	if [ -n "$1" ]; then
		NUMBER="$1"
	else
		NUMBER="$(choosenumbermenu)"
	fi

	DRAFT="$LOGDIR/$NUMBER/draft.txt"
	if [ ! -f "$DRAFT" ]; then
		mkdir -p "$(dirname "$DRAFT")"
		echo 'Enter text message here' > "$DRAFT"
	fi

	if [ "$TERMMODE" != "true" ]; then
		st -e "$EDITOR" "$DRAFT"
	else
		"$EDITOR" "$DRAFT"
	fi

	while true
	do
		CONFIRM="$(
			printf %b "$icon_edt Edit\n$icon_snd Send\n$icon_cls Cancel" |
			menu dmenu -c -idx 1 -p "Confirm" -l 10
		)"
		if echo "$CONFIRM" | grep -q "Send"; then
			(cat "$DRAFT" | sxmo_modemsendsms.sh "$NUMBER" -) && \
			rm "$DRAFT" && \
			echo "Sent text to $NUMBER">&2 && exit 0
		elif echo "$CONFIRM" | grep -q "Edit"; then
			sendtextmenu "$NUMBER"
		elif echo "$CONFIRM" | grep -q "Cancel"; then
			exit 1
		fi
	done
}

tailtextlog() {
	NUMBER="$1"
	CONTACTNAME="$(sxmo_contacts.sh | grep "^$NUMBER" | cut -d' ' -f2-)"
	[ "Unknown Number" = "$CONTACTNAME" ] && CONTACTNAME="$CONTACTNAME ($NUMBER)"

	set -- sh -c "tail -n9999 -f \"$LOGDIR/$NUMBER/sms.txt\" | sed \"s|$NUMBER|$CONTACTNAME|g\""
	if [ "$TERMMODE" != "true" ]; then
		st -T "$NUMBER SMS" -e "$@"
	else
		"$@"
	fi
}

readtextmenu() {
	# E.g. only display logfiles for directories that exist and join w contact name
	ENTRIES="$(
	printf %b "$icon_cls Close Menu\n$icon_edt Send a Text\n";
		sxmo_contacts.sh | while read -r CONTACT; do
			[ -d "$LOGDIR"/"$(printf %b "$CONTACT" | cut -d: -f1)" ] || continue
			printf %b "$CONTACT" | xargs -IL echo "L logfile"
		done
	)"
	PICKED="$(printf %b "$ENTRIES" | menu dmenu -p Texts -c -l 10 -i)"

	if echo "$PICKED" | grep "Close Menu"; then
		exit 1
	elif echo "$PICKED" | grep "Send a Text"; then
		sendtextmenu
	else
		tailtextlog "$(echo "$PICKED" | cut -d: -f1)"
	fi
}

if [ "2" != "$#" ]; then
	readtextmenu
else
	"$@"
fi
