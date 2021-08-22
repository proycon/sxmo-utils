#!/usr/bin/env sh

# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

valid_number() {
	if pn valid "$1"; then
		echo "$1"
		return
	fi

	REFORMATTED="$(pn find ${DEFAULT_COUNTRY:+-c "$DEFAULT_COUNTRY"} "$1")"
	if pn valid "$REFORMATTED"; then
		echo "$REFORMATTED"
		return
	fi

	notify-send "\"$1\" is not a valid phone number"

	PICKED="$(printf "Ok\nUse as it is\n" | dmenu -p "Invalid Number")"
	if [ "$PICKED" = "Use as it is" ]; then
		echo "$1"
		return
	fi

	exit
}

newcontact() {
	name="$(echo | sxmo_dmenu_with_kb.sh -p "$icon_usr Name")"
	number=
	while [ -z "$number" ]; do
		number="$(sxmo_contacts.sh --unknown | sxmo_dmenu_with_kb.sh -p "$icon_phl Number")"
		number="$(valid_number "$number")"
	done

	PICKED="$number	$name" # now act like if we picked this new contact
	echo "$PICKED" >> "$CONTACTFILE"
}

editcontactname() {
	oldnumber="$(echo "$1" | cut -d"	" -f1)"
	oldname="$(echo "$1" | cut -d"	" -f2)"

	ENTRIES="$(printf %b "Old name: $oldname")"
	PICKED="$(
		echo "$ENTRIES" |
		sxmo_dmenu_with_kb.sh -p "$icon_edt Edit Contact"
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

	ENTRIES="$(sxmo_contacts.sh --unknown | xargs -0 printf "%b (Old number)\n%b" "$oldnumber")"
	PICKED= # already used var name
	while [ -z "$PICKED" ]; do
		PICKED="$(
			echo "$ENTRIES" |
			sxmo_dmenu_with_kb.sh -p "$icon_edt Edit Contact"
		)"
		if echo "$PICKED" | grep -q "(Old number)$"; then
			editcontact "$1"
			return
		fi
		PICKED="$(valid_number "$PICKED")"
	done

	newcontact="$PICKED	$oldname"
	sed -i "s/^$1$/$newcontact/" "$CONTACTFILE"
	editcontact "$newcontact"
}

deletecontact() {
	name="$(echo "$1" | cut -d"	" -f2)"

	# shellcheck disable=SC2059
	ENTRIES="$(printf "$icon_cls No\n$icon_chk Yes")"
	PICKED="$(
		echo "$ENTRIES" |
		dmenu -p "$icon_del Delete $name ?"
	)"

	echo "$PICKED" | grep -q "Yes" && sed -i "/^$1$/d" "$CONTACTFILE"
}

editcontact() {
	number="$(echo "$1" | cut -d"	" -f1)"
	name="$(echo "$1" | cut -d"	" -f2)"
	ENTRIES="$(printf %b "$icon_ret Cancel\n$icon_usr Name: $name\n$icon_phl Number: $number")"

	PICKED="$(
		echo "$ENTRIES" |
		dmenu -p "$icon_edt Edit Contact"
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
	ENTRIES="$(printf %b "$icon_ret Cancel\n$icon_lst List Messages\n$icon_msg Send a Message\n$icon_phn Call\n$icon_edt Edit\n$icon_del Delete")"

	PICKED="$(
		echo "$ENTRIES" |
		dmenu -p "$icon_usr $name"
	)"

	if echo "$PICKED" | grep -q "List Messages"; then
		sxmo_modemtext.sh tailtextlog  "$number"
		exit
	elif echo "$PICKED" | grep -q "Send a Message"; then
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
		CONTACTS="$(sxmo_contacts.sh --all)"
		ENTRIES="$(echo "$CONTACTS" | xargs -0 printf "$icon_ret Close Menu\n$icon_pls New Contact\n%s")"

		PICKED="$(
			echo "$ENTRIES" |
			sxmo_dmenu_with_kb.sh -i -p "$icon_lst Contacts"
		)"

		echo "$PICKED" | grep -q "Close Menu" && exit
		echo "$PICKED" | grep -q "New Contact" && newcontact

		showcontact "$(echo "$PICKED" | sed 's/: /\t/g')"
	done
}

main
