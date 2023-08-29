#!/bin/sh -e
# title="󰎞 Notes"

# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh

DIR="${XDG_DATA_HOME:-$HOME/.local/share}/sxmo.notes"
mkdir -p "$DIR"

_listnotes() {
	( cd "$DIR" && find ./ -maxdepth 1 )  | cut -d/ -f2- | grep .
}

while : ; do
	ENTRIES="$(cat <<EOF
$icon_cls Close Menu
$icon_trh Delete
$(_listnotes)
EOF
)"
	PICKED="$(printf %b "$ENTRIES" | sxmo_dmenu.sh -p "Notes")" || break

	case "$PICKED" in
		"$icon_cls Close Menu"|"")
			break
			;;
		"$icon_trh Delete")
			ENTRIES="$(cat <<EOF
$icon_ret Cancel
$(_listnotes)
EOF
)"
			PICKED="$(printf %b "$ENTRIES" | sxmo_dmenu.sh -p "Notes - Delete")" || break
			if [ "$icon_ret Cancel" != "$PICKED" ]; then
				rm -f "$DIR"/"$PICKED"
			fi
			;;
		*)
			# shellcheck disable=SC2086
			sxmo_terminal.sh $EDITOR "$DIR"/"$PICKED"
			;;
	esac
done
