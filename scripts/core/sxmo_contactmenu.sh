#!/usr/bin/env sh

# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

newcontact() {
	name="$(echo | sxmo_dmenu_with_kb.sh -c -l 2 -p "Name")"
	number="$(echo | sxmo_dmenu_with_kb.sh -c -l 2 -p "Number")"

	PICKED="$number	$name" # now act like if we picked this new contact
	echo "$PICKED" >> "$CONTACTFILE"
}

editcontactname() {
	oldnumber="$(echo "$1" | cut -d"	" -f1)"
	oldname="$(echo "$1" | cut -d"	" -f2)"

	ENTRIES="$(printf %b "Old name: $oldname")"
	PICKED="$(
		echo "$ENTRIES" |
		sxmo_dmenu_with_kb.sh -c -l 3 -p "Edit Contact"
	)"

	if ! echo "$PICKED" | grep -q "^Old name: "; then
		newcontact="$oldnumber	$PICKED"
		sed -i "s/^$1$/$newcontact/" "$CONTACTFILE"
		set -- "$newcontact"
	fi

	editcontact "$1"
}

editcontactnumber() {
	oldnumber="$(echo "$1" | cut -d"	" -f1)"
	oldname="$(echo "$1" | cut -d"	" -f2)"

	ENTRIES="$(printf %b "Old number: $oldnumber")"
	PICKED="$(
		echo "$ENTRIES" |
		sxmo_dmenu_with_kb.sh -c -l 3 -p "Edit Contact"
	)"

	if ! echo "$PICKED" | grep -q "^Old number: "; then
		newcontact="$PICKED	$oldname"
		sed -i "s/^$1$/$newcontact/" "$CONTACTFILE"
		set -- "$newcontact"
	fi

	editcontact "$1"
}

deletecontact() {
	name="$(echo "$1" | cut -d"	" -f2)"

	ENTRIES="$(printf "Yes\nNo")"
	PICKED="$(
		echo "$ENTRIES" |
		dmenu -c -l 3 -p "Delete $name ?"
	)"

	echo "$PICKED" | grep -q "^Yes" && sed -i "/^$1$/d" "$CONTACTFILE"
}

editcontact() {
	number="$(echo "$1" | cut -d"	" -f1)"
	name="$(echo "$1" | cut -d"	" -f2)"
	ENTRIES="$(printf %b "Cancel\nName: $name\nNumber: $number")"

	PICKED="$(
		echo "$ENTRIES" |
		dmenu -c -l 4 -p "Edit Contact"
	)"

	if echo "$PICKED" | grep -q "^Name: "; then
		editcontactname "$1"
	elif echo "$PICKED" | grep -q "^Number: "; then
		editcontactnumber "$1"
	else
		showcontact "$1"
	fi
}

showcontact() {
	number="$(echo "$1" | cut -d"	" -f1)"
	name="$(echo "$1" | cut -d"	" -f2)"
	ENTRIES="$(printf %b "Cancel\nSend a Message\nCall\nEdit\nDelete")"

	PICKED="$(
		echo "$ENTRIES" |
		dmenu -c -l 5 -p "$name"
	)"

	if echo "$PICKED" | grep -q "^Send a Message"; then
		sxmo_modemtext.sh sendtextmenu  "$number"
		exit
	elif echo "$PICKED" | grep -q "^Call"; then
		sxmo_modemdial.sh "$number"
		exit
	elif echo "$PICKED" | grep -q "^Edit"; then
		editcontact "$1"
	elif echo "$PICKED" | grep -q "^Delete"; then
		deletecontact "$1" || showcontact "$1"
	fi
}

main() {
	while true; do
		CONTACTS="$(sed 's/\t/: /g' "$CONTACTFILE")"
		ENTRIES="$(echo "$CONTACTS" | xargs -0 printf "Close Menu\nNew Contact\n%s")"

		PICKED="$(
			echo "$ENTRIES" |
			sxmo_dmenu_with_kb.sh -i -c -l 10 -p "Contacts"
		)"

		echo "$PICKED" | grep -q "Close Menu" && exit
		echo "$PICKED" | grep -q "New Contact" && newcontact

		showcontact "$(echo "$PICKED" | sed 's/: /\t/g')"
	done
}

main
