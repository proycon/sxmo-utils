#!/usr/bin/env sh

# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

set -e

newcontact() {
	name="$(printf "" | sxmo_dmenu_with_kb.sh -p "$icon_usr Name")"

	number="$1"
	if [ -n "$number" ]; then
		number="$(sxmo_validnumber.sh "$number")"
	fi

	while [ -z "$number" ]; do
		number="$(sxmo_contacts.sh --unknown | sxmo_dmenu_with_kb.sh -p "$icon_phl Number")"
		number="$(sxmo_validnumber.sh "$number")"
	done

	PICKED="$number	$name" # now act like if we picked this new contact
	printf %s "$PICKED" >> "$CONTACTFILE"
}

editcontactname() {
	oldnumber="$(printf %s "$1" | cut -d"	" -f1)"
	oldname="$(printf %s "$1" | cut -d"	" -f2)"

	ENTRIES="$(printf %b "Old name: $oldname")"
	PICKED="$(
		printf %b "$ENTRIES" |
		sxmo_dmenu_with_kb.sh -p "$icon_edt Edit Contact"
	)"

	if ! printf %s "$PICKED" | grep -q "^Old name: "; then
		newcontact="$oldnumber	$PICKED"
		sed -i "s/^$1$/$newcontact/" "$CONTACTFILE"
		set -- "$newcontact"
	fi

	editcontact "$1"
}

editcontactnumber() {
	oldnumber="$(printf %s "$1" | cut -d"	" -f1)"
	oldname="$(printf %s "$1" | cut -d"	" -f2)"

	ENTRIES="$(sxmo_contacts.sh --unknown | xargs -0 printf "%b (Old number)\n%b" "$oldnumber")"
	PICKED= # already used var name
	while [ -z "$PICKED" ]; do
		PICKED="$(
			printf %b "$ENTRIES" |
			sxmo_dmenu_with_kb.sh -p "$icon_edt Edit Contact"
		)"
		if printf %s "$PICKED" | grep -q "(Old number)$"; then
			editcontact "$1"
			return
		fi
		PICKED="$(sxmo_validnumber.sh "$PICKED")"
	done

	newcontact="$PICKED	$oldname"
	sed -i "s/^$1$/$newcontact/" "$CONTACTFILE"
	editcontact "$newcontact"
}

deletecontact() {
	name="$(printf %s "$1" | cut -d"	" -f2)"

	# shellcheck disable=SC2059
	ENTRIES="$(printf "$icon_cls No\n$icon_chk Yes")"
	PICKED="$(
		printf %b "$ENTRIES" |
		dmenu -p "$icon_del Delete $name ?"
	)"

	printf %s "$PICKED" | grep -q "Yes" && sed -i "/^$1$/d" "$CONTACTFILE"
}

editcontact() {
	number="$(printf %s "$1" | cut -d"	" -f1)"
	name="$(printf %s "$1" | cut -d"	" -f2)"
	ENTRIES="$(printf %b "$icon_ret Cancel\n$icon_usr Name: $name\n$icon_phl Number: $number")"

	PICKED="$(
		printf %b "$ENTRIES" |
		dmenu -p "$icon_edt Edit Contact"
	)"

	case "$PICKED" in
		*"Name: "*)
			editcontactname "$1"
			;;
		*"Number: "*)
			editcontactnumber "$1"
			;;
		*)
			showcontact "$1"
			;;
	esac

}

showcontact() {
	number="$(printf %s "$1" | cut -d"	" -f1)"
	name="$(printf %s "$1" | cut -d"	" -f2)"
	ENTRIES="$(printf %b "$icon_ret Cancel\n$icon_lst List Messages\n$icon_msg Send a Message\n$icon_phn Call\n$icon_edt Edit\n$icon_del Delete")"

	PICKED="$(
		printf %b "$ENTRIES" |
		dmenu -p "$icon_usr $name"
	)"

	case "$PICKED" in
		 *"List Messages")
			sxmo_modemtext.sh tailtextlog  "$number"
			exit
			;;
		 *"Send a Message")
			sxmo_modemtext.sh sendtextmenu  "$number"
			exit
			;;
		 *"Call")
			sxmo_modemdial.sh "$number"
			exit
			;;
		 *"Edit")
			editcontact "$1"
			;;
		 *"Delete")
			deletecontact "$1" || showcontact "$1"
			;;
	esac
}

main() {
	while true; do
		CONTACTS="$(sxmo_contacts.sh --all)"
		ENTRIES="$(printf %b "$CONTACTS" | xargs -0 printf "$icon_ret Close Menu\n$icon_pls New Contact\n%s")"

		PICKED="$(
			printf %b "$ENTRIES" |
			sxmo_dmenu_with_kb.sh -i -p "$icon_lst Contacts"
		)"

		printf %s "$PICKED" | grep -q "Close Menu" && exit
		printf %s "$PICKED" | grep -q "New Contact" && newcontact

		showcontact "$(printf %s "$PICKED" | sed 's/: /\t/g')"
	done
}

if [ -n "$1" ]; then
	cmd="$1"
	shift
else
	cmd=main
fi

"$cmd" "$@"
