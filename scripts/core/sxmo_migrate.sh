#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(which sxmo_common.sh)"

smartdiff() {
	if command -v colordiff > /dev/null; then
		colordiff "$@"
	else
		diff "$@"
	fi
}

resolvedifference() {
	userfile="$1"
	defaultfile="$2"

	(
		printf "\e[31mThe file \e[32m%s\e[31m differs\e[0m\n" "$userfile"
		smartdiff -ud "$userfile" "$defaultfile"
	) | less -RF

	printf "\e[33mDo you want to apply the default? [y/N], or perhaps open an editor [e]?\e[0m "
	read -r reply < /dev/tty
	if [ "y" = "$reply" ]; then
		cp "$defaultfile" "$userfile"
	elif [ "e" = "$reply" ]; then
		$EDITOR "$userfile" "$defaultfile"
	fi
}

defaultconfig() {
	if [ ! -r "$2" ]; then
		mkdir -p "$(dirname "$2")"
		cp "$1" "$2"
		chmod "$3" "$2"
	else
		if ! diff "$2" "$1" > /dev/null; then
			resolvedifference "$2" "$1"
		fi
	fi
}

checkhooks() {
	if [ -e "$XDG_CONFIG_HOME/sxmo/hooks/" ]; then
		for hook in "$XDG_CONFIG_HOME/sxmo/hooks/"*; do
			defaulthook="/usr/share/sxmo/default_hooks/$(basename "$hook")"
			if [ -f "$defaulthook" ]; then
				if ! diff "$hook" "$defaulthook" > /dev/null; then
					resolvedifference "$hook" "$defaulthook"
				else
					printf "\e[33mHook %s is identical to the default, so you don't need a custom hook, remove it? [Y/n]\e[0m" "$hook"
					if [ "n" != "$reply" ]; then
						rm "$hook"
					fi
				fi
			fi
		done
	fi
}

defaultconfig /usr/share/sxmo/appcfg/xinit_template "$XDG_CONFIG_HOME/sxmo/xinit" 744
checkhooks
