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

	#finish the migration, removing .needs-migration and moving to right place
	case "$userfile" in
		*needs-migration)
			mv -f "$userfile" "${userfile%.needs-migration}"
			;;
	esac
	printf "\n"
}

checkconfigversion() {
	userfile="$1"
	reffile="$2"
	if [ ! -e "$userfile" ] || [ ! -e "$reffile" ]; then
		#if the userfile doesn't exist then we revert to default anyway so it's considered up to date
		return 0
	fi
	refversion=$(grep -e "^[#;]\\s*configversion\\s*[:=]" "$reffile" |  tr -d '#;:=[:space:]')
	userversion=$(grep -e "^[#;]\\s*configversion\\s*[:=]" "$userfile" |  tr -d '#;:=[:space:]')
	if [ -z "$userversion" ]; then
		#no user version found, check file contents instead
		tmpreffile="${XDG_RUNTIME_DIR}/versioncheck"
		grep -ve "^[#;]\\s*configversion\\s*[:=]" "$reffile" > "$tmpreffile"
		if diff "$tmpreffile" "$userfile" > /dev/null; then
			rm "$tmpreffile"
			return 0
		else
			rm "$tmpreffile"
			return 1
		fi
	else
		[ "$refversion" = "$userversion" ]
	fi
}

defaultconfig() {
	defaultfile="$1"
	userfile="$2"
	filemode="$3"
	if [ -e "$userfile.needs-migration" ] && { [ "$MODE" = "interactive" ] || [ "$MODE" = "all" ]; }; then
		resolvedifference "$userfile.needs-migration" "$defaultfile"
		chmod "$filemode" "$userfile" 2> /dev/null
	elif [ ! -r "$userfile" ]; then
		mkdir -p "$(dirname "$userfile")"
		sxmo_log "Installing default configuration $userfile..."
		cp "$defaultfile" "$userfile"
		chmod "$filemode" "$userfile"
	elif [ "$MODE" = "reset" ]; then
		[ ! -e "$userfile.needs-migration" ] && mv "$userfile" "$userfile.needs-migration"
		cp "$defaultfile" "$userfile"
		chmod "$filemode" "$userfile"
	elif ! checkconfigversion "$userfile" "$defaultfile" || [ "$MODE" = "all" ]; then
		case "$MODE" in
			"interactive"|"all")
				resolvedifference "$userfile" "$defaultfile"
				;;
			"sync")
				sxmo_log "$userfile is out of date, disabling and marked as needing migration..."
				[ ! -e "$userfile.needs-migration" ] && cp "$userfile" "$userfile.needs-migration" #never overwrite older .needs-migration files, they take precendence
				chmod "$filemode" "$userfile.needs-migration"
				cp "$defaultfile" "$userfile"
				chmod "$filemode" "$userfile"
				;;
		esac
	fi
}

checkhooks() {
	if [ -e "$XDG_CONFIG_HOME/sxmo/hooks/" ]; then
		for hook in "$XDG_CONFIG_HOME/sxmo/hooks/"*; do
			if [ "$MODE" = "reset" ]; then
				if [ ! -e "$hook.needs-migration" ]; then
					mv "$hook" "$hook.needs-migration" #move the hook away
				else
					rm "$hook"
				fi
				continue
			fi
			case "$hook" in
				*.needs-migration)
					defaulthook="/usr/share/sxmo/default_hooks/$(basename "$hook" ".needs-migration")"
					[ "$MODE" = sync ] && continue # ignore this already synced hook
					;;
				*.backup)
					#skip
					continue
					;;
				*)
					#if there is already one marked as needing migration, use that one instead and skip this one
					[ -e "$hook.needs-migration" ] && continue
					defaulthook="/usr/share/sxmo/default_hooks/$(basename "$hook")"
					;;
			esac
			if [ -f "$defaulthook" ]; then
				if diff "$hook" "$defaulthook" > /dev/null && [ "$MODE" != "sync" ]; then
					printf "\e[33mHook %s is identical to the default, so you don't need a custom hook, remove it? [Y/n]\e[0m" "$hook"
					read -r reply < /dev/tty
					if [ "n" != "$reply" ]; then
						rm "$hook"
					fi
				elif ! checkconfigversion "$hook" "$defaulthook" || [ "$MODE" = "all" ]; then
					case "$MODE" in
						"interactive"|"all")
							resolvedifference "$hook" "$defaulthook"
							;;
						"sync")
							sxmo_log "$hook is out of date, disabling and marked as needing migration..."
							#never overwrite older .needs-migration files, they take precendence
							if [ ! -e "$hook.needs-migration" ]; then
								mv "$hook" "$hook.needs-migration"
							else
								rm "$hook"
							fi
							;;
					esac
				fi
			elif [ "$MODE" != "sync" ]; then
				(
					smartdiff -ud "/dev/null" "$hook"
					printf "\e[31mThe hook \e[32m%s\e[31m does not exist (anymore), remove it? [Y/n] \e[0m\n" "$hook"
					read -r reply < /dev/tty
					if [ "n" != "$reply" ]; then
						rm "$hook"
					fi
				) | more
				printf "\n"
			fi
		done
	fi
}

common() {
	defaultconfig /usr/share/sxmo/appcfg/profile_template "$XDG_CONFIG_HOME/sxmo/profile" 644
}

sway() {
	defaultconfig /usr/share/sxmo/appcfg/sway_template "$XDG_CONFIG_HOME/sxmo/sway" 644
	defaultconfig /usr/share/sxmo/appcfg/foot.ini "$XDG_CONFIG_HOME/foot/foot.ini" 644
	defaultconfig /usr/share/sxmo/appcfg/mako.conf "$XDG_CONFIG_HOME/mako/config" 644
}

xorg() {
	defaultconfig /usr/share/sxmo/appcfg/xinit_template "$XDG_CONFIG_HOME/sxmo/xinit" 644
	defaultconfig /usr/share/sxmo/appcfg/dunst.conf "$XDG_CONFIG_HOME/dunst/dunstrc" 644
}


MODE="interactive" #default mode
[ -n "$1" ] && MODE="$1"

case "$MODE" in
	"interactive"|"all"|"sync"|"reset")
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
		;;
	"state")
		NEED_MIGRATION="$(find "$XDG_CONFIG_HOME/sxmo/" -name "*.needs-migration")"
		if [ -n "$NEED_MIGRATION" ]; then
			sxmo_log "The following configuration files need migration: $NEED_MIGRATION"
			exit "$(echo "$NEED_MIGRATION" | wc -l)" #exit code represents number of files needing migration
		else
			sxmo_log "All configuration files are up to date"
		fi
		;;
	*)
		sxmo_log "Invalid mode: $MODE"
		exit 2
		;;
esac
