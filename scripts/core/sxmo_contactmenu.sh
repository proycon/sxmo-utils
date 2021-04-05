#!/usr/bin/env sh

# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

newcontact() {
	name="$(echo | sxmo_dmenu_with_kb.sh -c -l 2 -p "$icon_usr Name")"
	number="$(echo | sxmo_dmenu_with_kb.sh -c -l 2 -p "$icon_phl Number")"

	PICKED="$number	$name" # now act like if we picked this new contact
	echo "$PICKED" >> "$CONTACTFILE"
}

editcontactname() {
	oldnumber="$(echo "$1" | cut -d"	" -f1)"
	oldname="$(echo "$1" | cut -d"	" -f2)"

	ENTRIES="$(printf %b "Old name: $oldname")"
	PICKED="$(
		echo "$ENTRIES" |
		sxmo_dmenu_with_kb.sh -c -l 3 -p "$icon_edt Edit Contact"
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
		sxmo_dmenu_with_kb.sh -c -l 3 -p "$icon_edt Edit Contact"
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

	# shellcheck disable=SC2059
	ENTRIES="$(printf "$icon_cls No\n$icon_chk Yes")"
	PICKED="$(
		echo "$ENTRIES" |
		dmenu -c -l 3 -p "$icon_del Delete $name ?"
	)"

	echo "$PICKED" | grep -q "Yes" && sed -i "/^$1$/d" "$CONTACTFILE"
}

editcontact() {
	number="$(echo "$1" | cut -d"	" -f1)"
	name="$(echo "$1" | cut -d"	" -f2)"
	ENTRIES="$(printf %b "$icon_ret Cancel\n$icon_usr Name: $name\n$icon_phl Number: $number")"

	PICKED="$(
		echo "$ENTRIES" |
		dmenu -c -l 4 -p "$icon_edt Edit Contact"
	)"

	if echo "$PICKED" | grep -q "Name: "; then
		editcontactname "$1"
	elif echo "$PICKED" | grep -q "Number: "; then
		editcontactnumber "$1"
	else
		showcontact "$1"
	fi
}

showcontact() {
	number="$(echo "$1" | cut -d"	" -f1)"
	name="$(echo "$1" | cut -d"	" -f2)"
	ENTRIES="$(printf %b "$icon_ret Cancel\n$icon_msg Send a Message\n$icon_phn Call\n$icon_edt Edit\n$icon_del Delete")"

	PICKED="$(
		echo "$ENTRIES" |
		dmenu -c -l 5 -p "$icon_usr $name"
	)"

	if echo "$PICKED" | grep -q "Send a Message"; then
		sxmo_modemtext.sh sendtextmenu  "$number"
		exit
	elif echo "$PICKED" | grep -q "Call"; then
		sxmo_modemdial.sh "$number"
		exit
	elif echo "$PICKED" | grep -q "Edit"; then
		editcontact "$1"
	elif echo "$PICKED" | grep -q "Delete"; then
		deletecontact "$1" || showcontact "$1"
	fi
}

main() {
	while true; do
		CONTACTS="$(sed 's/\t/: /g' "$CONTACTFILE")"
		ENTRIES="$(echo "$CONTACTS" | xargs -0 printf "$icon_ret Close Menu\n$icon_pls New Contact\n%s")"

		PICKED="$(
			echo "$ENTRIES" |
			sxmo_dmenu_with_kb.sh -i -c -l 10 -p "$icon_lst Contacts"
		)"

		echo "$PICKED" | grep -q "Close Menu" && exit
		echo "$PICKED" | grep -q "New Contact" && newcontact

		showcontact "$(echo "$PICKED" | sed 's/: /\t/g')"
	done
}

main
