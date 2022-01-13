#!/bin/sh

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
		smartdiff -ud "$defaultfile" "$userfile"
	) | more

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

common() {
	defaultconfig /usr/share/sxmo/appcfg/profile_template "$XDG_CONFIG_HOME/sxmo/profile" 744
}

sway() {
	defaultconfig /usr/share/sxmo/appcfg/sway_template "$XDG_CONFIG_HOME/sxmo/sway" 744
	defaultconfig /usr/share/sxmo/appcfg/foot.ini "$XDG_CONFIG_HOME/foot/foot.ini" 744
	defaultconfig /usr/share/sxmo/appcfg/mako.conf "$XDG_CONFIG_HOME/mako/config" 744
}

xorg() {
	defaultconfig /usr/share/sxmo/appcfg/xinit_template "$XDG_CONFIG_HOME/sxmo/xinit" 744
	defaultconfig /usr/share/sxmo/appcfg/dunst.conf "$XDG_CONFIG_HOME/dunst/dunstrc" 744
}

case "$SXMO_WM" in
	sway)
		common
		sway
		;;
	dwm)
		common
		xorg
		;;
	*)
		common
		sway
		xorg
		;;
esac

checkhooks
