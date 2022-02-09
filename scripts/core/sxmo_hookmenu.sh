#! /bin/sh

# shellcheck source=scripts/core/sxmo_icons.sh
. sxmo_icons.sh

set -e

copy() {
	mkdir -p "$XDG_CONFIG_HOME/sxmo/hooks"

	if [ ! -e "$XDG_CONFIG_HOME/sxmo/hooks/$1" ]; then
		cp "/usr/share/sxmo/default_hooks/$1" \
			"$XDG_CONFIG_HOME/sxmo/hooks/$1"
	fi
}

edit() {
	copy "$1"
	sxmo_terminal.sh "$EDITOR" "$XDG_CONFIG_HOME/sxmo/hooks/$1" || true # shallow
}

reset() {
	if [ -f "$XDG_CONFIG_HOME/sxmo/hooks/$1" ]; then
		rm "$XDG_CONFIG_HOME/sxmo/hooks/$1"
	fi
}

hookmenu() {
	opt="$(cat <<EOF | sxmo_dmenu.sh -p "$1"
$icon_ret Return
$icon_edt Edit
$([ -f "$XDG_CONFIG_HOME/sxmo/hooks/$1" ] && echo "$icon_cls Use system hook" || echo "$icon_cpy Copy")
EOF
	)" || return

	case "$opt" in
		"$icon_edt Edit") edit "$1";;
		"$icon_cpy Copy") copy "$1";;
		"$icon_cls Use system hook") reset "$1";;
		"$icon_ret Return") return;;
	esac
}

list_hooks() {
	user=$(mktemp)
	system=$(mktemp)

	if [ -d "$XDG_CONFIG_HOME/sxmo/hooks" ]; then
		find "$XDG_CONFIG_HOME/sxmo/hooks" \( -type f -o -type l \) -exec basename -a {} + |\
			sort > "$user"
	fi

	find "/usr/share/sxmo/default_hooks" \( -type f -o -type l \) -exec basename -a {} + |\
		sort > "$system"

	# TODO: someone please find some good icons for this
	# Present in the user directory only (not in default hooks)
	comm -23 "$user" "$system" | sed 's/^/X /g'
	# In both directories (overrideing a system hook)
	comm -12 "$user" "$system" | sed 's/^/U /g'
	# System hook only (not in the user directory)
	comm -13 "$user" "$system" | sed 's/^/S /g'

	rm "$user" "$system"
}

menu() {
	while : ; do
		hook="$(cat <<EOF | sxmo_dmenu.sh
$icon_cls Close Menu
$(list_hooks)
EOF
		)" || return;

		case "$hook" in
			"$icon_cls Close Menu")
				return
				;;
			*)
				hookmenu "${hook#* }"
				;;
		esac
	done
}

if [ -z "$1" ]; then
	set -- menu
fi

"$@"
