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

defaultconfig() {
	if [ ! -r "$2" ]; then
		mkdir -p "$(dirname "$2")"
		cp "$1" "$2"
		chmod "$3" "$2"
	else
		if ! diff "$2" "$1" > /dev/null; then
			(
				printf "\e[31mThe file \e[32m%s\e[31m differs\e[0m\n" "$2"
				smartdiff -ud "$2" "$1"
			) | less -RF
			printf "\e[33mDo you want to apply the default? [y/N], or perhaps open an editor [e]?\e[0m "
			read -r reply < /dev/tty
			if [ "y" = "$reply" ]; then
				cp "$1" "$2"
			elif [ "e" = "$reply" ]; then
				$EDITOR "$2" "$1"
			fi
		fi
	fi
}

checkhooks() {
	if [ -e "$XDG_CONFIG_HOME/sxmo/hooks/" ]; then
		for hook in "$XDG_CONFIG_HOME/sxmo/hooks/"*; do
			defaulthook="/usr/share/sxmo/default_hooks/$(basename "$hook")"
			if [ -f "$defaulthook" ]; then
				if ! diff "$hook" "$defaulthook" > /dev/null; then
					(
						printf "\e[31mThe file \e[32m%s\e[31m differs\e[0m\n" "$hook"
						smartdiff -ud "$hook" "$defaulthook"
					) | less -RF
					printf "\e[33mDo you want to remove the custom hook and fall back to the default? [y/N], or perhaps open an editor [e]?\e[0m"
					read -r reply < /dev/tty
					if [ "y" = "$reply" ]; then
						rm "$hook"
					elif [ "e" = "$reply" ]; then
						$EDITOR "$hook" "$defaulthook"
					fi
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
