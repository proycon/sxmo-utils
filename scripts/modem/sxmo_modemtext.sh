#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

set -e

err() {
	echo "$1">&2
	echo "$1" | dmenu
	kill $$
}

choosenumbermenu() {
	# Prompt for number
	NUMBER="$(
		printf %b "\n$icon_cls Cancel\n$icon_grp More contacts\n$(sxmo_contacts.sh | grep -E "\+[0-9]+$")" |
		awk NF |
		sxmo_dmenu_with_kb.sh -p "Number" -i |
		cut -d: -f2 |
		tr -d -- '- '
	)"

	if echo "$NUMBER" | grep -q "Morecontacts"; then
		NUMBER="$( #joined words without space is not a bug
			printf %b "\nCancel\n$(sxmo_contacts.sh --all)" |
				grep . |
				sxmo_dmenu_with_kb.sh -p "Number" -i |
				cut -d: -f2 |
				tr -d -- '- '
		)"
	fi

	if printf %s "$NUMBER" | grep -q "Cancel"; then
		exit 1
	elif NUMBER="$(sxmo_validnumber.sh "$NUMBER")"; then
		printf %s "$NUMBER"
	else
		notify-send "That doesn't seem like a valid number"
	fi
}

sendtextmenu() {
	if [ -n "$1" ]; then
		NUMBER="$1"
	else
		NUMBER="$(choosenumbermenu)"
	fi

	[ -z "$NUMBER" ] && exit 1

	DRAFT="$LOGDIR/$NUMBER/draft.txt"
	if [ ! -f "$DRAFT" ]; then
		mkdir -p "$(dirname "$DRAFT")"
		echo 'Enter text message here' > "$DRAFT"
	fi

	sxmo_terminal.sh "$EDITOR" "$DRAFT"

	while true
	do
		ATTACHMENTS=
		if [ -f "$LOGDIR/$NUMBER/draft.attachments.txt" ]; then
			ATTACHMENTS="$(tr '\n' '\0' < "$LOGDIR/$NUMBER/draft.attachments.txt" | xargs -0 printf "Remove file %s\n")"
		fi

		RECIPIENTS=
		if [ "$(printf %s "$NUMBER" | xargs pn find | wc -l)" -gt 1 ]; then
			RECIPIENTS="$(printf %s "$NUMBER" | xargs pn find | xargs printf "Remove recipient %s\n")"
		fi

		CHOICES="$(printf "%s Send (%s)\n%b\n%s Add Attachment\n%b\n%s Add Recipient\n%s Edit '%s'\n%s Cancel\n" \
				"$icon_snd" "$NUMBER" "$ATTACHMENTS" "$icon_att" "$RECIPIENTS" "$icon_usr" "$icon_edt" \
				"$(cat "$LOGDIR/$NUMBER/draft.txt")" "$icon_cls" \
				| awk NF
		)"

		CONFIRM="$(printf %b "$CHOICES" | dmenu -i -p "Confirm")"
		case "$CONFIRM" in
			*"Send"*)
				if sxmo_modemsendsms.sh "$NUMBER" - < "$DRAFT"; then
					rm "$DRAFT"
					echo "Sent text to $NUMBER">&2
					exit 0
				else
					err "Failed to send txt to $NUMBER"
				fi
				;;
			"Remove file"*)
				FILE="$(printf %s "$CONFIRM" | cut -d' ' -f3-)"
				sed -i "\|$FILE|d" "$LOGDIR/$NUMBER/draft.attachments.txt"
				if [ ! -s "$LOGDIR/$NUMBER/draft.attachments.txt" ] ; then
					rm "$LOGDIR/$NUMBER/draft.attachments.txt"
				fi
				;;
			"Remove recipient"*)
				if [ "$(printf %s "$NUMBER" | xargs pn find | wc -l)" -gt 1 ]; then 
					OLDNUMBER="$NUMBER"
					RECIPIENT="$(printf %s "$CONFIRM" | cut -d' ' -f3-)"
					NUMBER="$(printf %s "$OLDNUMBER" | sed "s/$RECIPIENT//")"
					mkdir -p "$LOGDIR/$NUMBER"
					DRAFT="$LOGDIR/$NUMBER/draft.txt"
					if [ -f "$LOGDIR/$OLDNUMBER/draft.txt" ]; then
						# TODO: if there is already a DRAFT warn the user?
						mv "$LOGDIR/$OLDNUMBER/draft.txt" "$DRAFT"
					fi
					if [ -f "$LOGDIR/$OLDNUMBER/draft.attachments.txt" ]; then
						mv "$LOGDIR/$OLDNUMBER/draft.attachments.txt" \
							"$LOGDIR/$NUMBER/draft.attachments.txt"
					fi
				fi
				;;
			*"Edit"*)
				sendtextmenu "$NUMBER"
				;;
			*"Add Attachment")
				ATTACHMENT="$(sxmo_files.sh "$HOME" selectonly)"
				if [ -f "$ATTACHMENT" ]; then
					printf "%s\n" "$ATTACHMENT" >> "$LOGDIR/$NUMBER/draft.attachments.txt"
				fi
				;;
			*"Add Recipient")
				OLDNUMBER="$NUMBER"
				ADDEDNUMBER="$(choosenumbermenu)"

				if ! echo "$ADDEDNUMBER" | grep -q '^+'; then
					echo "We can't add numbers that don't start with +"
				elif echo "$OLDNUMBER" | grep -q "$ADDEDNUMBER"; then
					echo "Number already a recipient."
				else
					NUMBER="$(printf %s%s "$NUMBER" "$ADDEDNUMBER" | xargs pn find | sort -u | tr -d '\n')"
					mkdir -p "$LOGDIR/$NUMBER"
					DRAFT="$LOGDIR/$NUMBER/draft.txt"
					if [ -f "$LOGDIR/$OLDNUMBER/draft.txt" ]; then
						# TODO: if there is already a DRAFT warn the user?
						mv "$LOGDIR/$OLDNUMBER/draft.txt" "$DRAFT"
					fi
					if [ -f "$LOGDIR/$OLDNUMBER/draft.attachments.txt" ]; then
						mv "$LOGDIR/$OLDNUMBER/draft.attachments.txt" \
						"$LOGDIR/$NUMBER/draft.attachments.txt"
					fi
				fi
				;;
			*"Cancel")
				exit 1
				;;
		esac
	done
}

conversationloop() {
	if [ -n "$1" ]; then
		NUMBER="$1"
	else
		NUMBER="$(choosenumbermenu)"
	fi

	set -e

	sxmo_keyboard.sh open

	while true; do
		DRAFT="$LOGDIR/$NUMBER/draft.txt"
		if [ ! -f "$DRAFT" ]; then
			mkdir -p "$(dirname "$DRAFT")"
			touch "$DRAFT"
		fi

		"$EDITOR" "$DRAFT"
		sxmo_modemsendsms.sh "$NUMBER" - < "$DRAFT" || continue
		rm "$DRAFT"
	done
}

tailtextlog() {
	NUMBER="$1"
	CONTACTNAME="$(sxmo_contacts.sh | grep ": ${NUMBER}$" | cut -d: -f1)"
	[ "???" = "$CONTACTNAME" ] && CONTACTNAME="$CONTACTNAME ($NUMBER)"

	TERMNAME="$NUMBER SMS" sxmo_terminal.sh sh -c "tail -n9999 -f \"$LOGDIR/$NUMBER/sms.txt\" | sed \"s|$NUMBER|$CONTACTNAME|g\""
}

readtextmenu() {
	# E.g. only display logfiles for directories that exist and join w contact name
	ENTRIES="$(
	printf %b "$icon_cls Close Menu\n$icon_edt Send a Text\n";
		sxmo_contacts.sh --texted | xargs -IL echo "L logfile"
	)"
	PICKED="$(printf %b "$ENTRIES" | sxmo_dmenu_with_kb.sh -p "Texts" -i)" || exit

	if echo "$PICKED" | grep "Close Menu"; then
		exit 1
	elif echo "$PICKED" | grep "Send a Text"; then
		sendtextmenu
	else
		tailtextlog "$(echo "$PICKED" | cut -d: -f2 | sed 's/^ //' | cut -d' ' -f1 )"
	fi
}

if [ "2" != "$#" ]; then
	readtextmenu
else
	"$@"
fi
