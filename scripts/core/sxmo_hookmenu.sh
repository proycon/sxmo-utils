#! /bin/sh

set -e

copy() {
	if [ ! -e "$XDG_CONFIG_HOME/sxmo/hooks/$1" ]; then
		cp "/usr/share/sxmo/default_hooks/$1" \
			"$XDG_CONFIG_HOME/sxmo/hooks/$1"
	fi
}

edit() {
	copy "$1"
	sxmo_terminal.sh "$EDITOR" "$XDG_CONFIG_HOME/sxmo/hooks/$1"
}

reset() {
	if [ -f "$XDG_CONFIG_HOME/sxmo/hooks/$1" ]; then
		rm "$XDG_CONFIG_HOME/sxmo/hooks/$1"
	fi
}

hookmenu() {
	opt="$(cat <<EOF | sxmo_dmenu.sh -p "$1"
Edit
$([ -f "$XDG_CONFIG_HOME/sxmo/hooks/$1" ] && echo "Use system hook" || echo Copy)
Exit
EOF
	)" || return


	case "$opt" in
		"Edit") edit "$1";;
		"Copy") copy "$1";;
		"Use system hook") reset "$1";;
		"Exit") return;;
	esac
}

list_hooks() {
	user=$(mktemp)
	system=$(mktemp)

	# dmenu can't handle itmes with newlines in them, so we don't handle them
	find "$XDG_CONFIG_HOME/sxmo/hooks" -type f -print0 |\
		xargs -0 basename -a | sort > "$user"

	find "/usr/share/sxmo/default_hooks" -type f -print0 |\
		xargs -0 basename -a | sort > "$system"

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
	hook="$( (echo "Exit"; list_hooks) | sxmo_dmenu.sh)" || return;
	if [ "$hook" = "Exit" ]; then
		return
	else
		hook=${hook#* }
	fi
	hookmenu "$hook"
}

if [ -z "$1" ]; then
	set -- menu
fi

"$@"
