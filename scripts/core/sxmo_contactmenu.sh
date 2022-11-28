#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

set -e

# shellcheck disable=SC2120
newcontact() {
	name="$(printf "" | sxmo_dmenu_with_kb.sh -p "$icon_usr Name")"

	number="$1"
	if [ -n "$number" ]; then
		number="$(sxmo_validnumber.sh "$number")" || return
	fi

	while [ -z "$number" ]; do
		number="$(sxmo_contacts.sh --unknown | sxmo_dmenu_with_kb.sh -p "$icon_phl Number")"
		number="$(sxmo_validnumber.sh "$number")" || continue
	done

	# we store as NUMBER\tNAME but display as NAME\tNUMBER
	printf "%s\n" "$number	$name" >> "$SXMO_CONTACTFILE"
	PICKED="$name	$number"
}

editcontactname() {
	oldnumber="$(printf %s "$1" | cut -d"	" -f2)"
	oldname="$(printf %s "$1" | cut -d"	" -f1)"

	ENTRIES="$(printf %b "Old name: $oldname")"
	PICKED="$(
		printf %b "$ENTRIES" |
		sxmo_dmenu_with_kb.sh -p "$icon_edt Edit Contact"
	)"

	if ! printf %s "$PICKED" | grep -q "^Old name: "; then
		newcontact="$oldnumber	$PICKED"
		sed -i "s/^$oldnumber	$oldname$/$newcontact/" "$SXMO_CONTACTFILE"
		set -- "$newcontact"
	fi

	editcontact "$PICKED	$oldnumber"
}

editcontactnumber() {
	oldnumber="$(printf %s "$1" | cut -d"	" -f2)"
	oldname="$(printf %s "$1" | cut -d"	" -f1)"

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
		PICKED="$(sxmo_validnumber.sh "$PICKED")" || continue
	done

	newcontact="$PICKED	$oldname"

	# reverse them
	sed -i "s/^$number	$name$/$newcontact/" "$SXMO_CONTACTFILE"
	editcontact "$oldname	$PICKED"
}

deletecontact() {
	number="$(printf %s "$1" | cut -d"	" -f2)"
	name="$(printf %s "$1" | cut -d"	" -f1)"

	# shellcheck disable=SC2059
	ENTRIES="$(printf "$icon_cls No\n$icon_chk Yes")"
	PICKED="$(
		printf %b "$ENTRIES" |
		dmenu -p "$icon_del Delete $name ?"
	)"

	# reverse them
	printf %s "$PICKED" | grep -q "Yes" && sed -i "/^$number	$name$/d" "$SXMO_CONTACTFILE"
}

editcontact() {
	number="$(printf %s "$1" | cut -d"	" -f2)"
	name="$(printf %s "$1" | cut -d"	" -f1)"
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
	number="$(printf %s "$1" | cut -d"	" -f2)"
	name="$(printf %s "$1" | cut -d"	" -f1)"
	ENTRIES="$(printf %b "$icon_ret Cancel\n$icon_lst List Messages\n$icon_msg Send a Message\n$icon_phn Call\n$icon_edt Edit\n$icon_del Delete")"

	PICKED="$(
		printf %b "$ENTRIES" |
		dmenu -p "$icon_usr $name"
	)"

	case "$PICKED" in
		*"List Messages")
			sxmo_hook_tailtextlog.sh  "$number"
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

		case "$PICKED" in
			"$icon_ret Close Menu")
				exit
				;;
			"$icon_pls New Contact")
				newcontact || continue
				;;
			*)
		esac

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
