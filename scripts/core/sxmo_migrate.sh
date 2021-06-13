#!/usr/bin/env sh

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
			) | less -RXF
			printf "\e[33mDo you want to apply the default? [y/N]\e[0m "
			read -r reply < /dev/tty
			if [ "y" = "$reply" ]; then
				cp "$1" "$2"
			fi
		fi
	fi
}

defaultconfigs() {
	defaultconfig /usr/share/sxmo/appcfg/xinit_template "$XDG_CONFIG_HOME/sxmo/xinit" 744
	defaultconfig /usr/share/sxmo/default_hooks/discard "$XDG_CONFIG_HOME/sxmo/hooks/discard" 744
	defaultconfig /usr/share/sxmo/default_hooks/missed_call "$XDG_CONFIG_HOME/sxmo/hooks/missed_call" 744
	defaultconfig /usr/share/sxmo/default_hooks/mute_ring "$XDG_CONFIG_HOME/sxmo/hooks/mute_ring" 744
	defaultconfig /usr/share/sxmo/default_hooks/pickup "$XDG_CONFIG_HOME/sxmo/hooks/pickup" 744
	defaultconfig /usr/share/sxmo/default_hooks/postwake "$XDG_CONFIG_HOME/sxmo/hooks/postwake" 744
	defaultconfig /usr/share/sxmo/default_hooks/ring "$XDG_CONFIG_HOME/sxmo/hooks/ring" 744
	defaultconfig /usr/share/sxmo/default_hooks/rtcwake "$XDG_CONFIG_HOME/sxmo/hooks/rtcwake" 744
	defaultconfig /usr/share/sxmo/default_hooks/sms "$XDG_CONFIG_HOME/sxmo/hooks/sms" 744
}

defaultconfigs
