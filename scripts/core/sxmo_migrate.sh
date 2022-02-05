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

	printf "\e[31mMigration options for \e[32m%s\e[31m:\e[0m\n" "$userfile"

	printf "1 - Use [d]efault. Apply the Sxmo default, discarding all your own changes.\n"
	printf "2 - Open [e]ditor and merge the changes yourself; take care to set the same configversion.\n"
	printf "3 - Use your [u]ser version as-is; you verified it's compatible. (Auto-updates configversion only).\n"
	printf "4 - [i]gnore, do not resolve and don't change anything, ask again next time. (default)\n"

	printf "\e[33mHow do you want to resolve this? Choose one of the options above [1234deui]\e[0m "

	read -r reply < /dev/tty
	abort=0
	case "$reply" in
		[1dD]*)
			#use default
			case "$userfile" in
				*hooks*)
					#just remove the user hook, will use default automatically
					rm "$userfile"
					abort=1 #no need for any further cleanup
					;;
				*)
					cp "$defaultfile" "$userfile" || abort=1
					;;
			esac
			;;
		[2eE]*)
			#open editor with both files and the diff
			diff -u "$defaultfile" "$userfile" > "${XDG_RUNTIME_DIR}/migrate.diff"
			if ! $EDITOR "$userfile" "$defaultfile" "${XDG_RUNTIME_DIR}/migrate.diff"; then
				#user may bail editor, in which case we ignore everything
				abort=1
			fi
			rm "${XDG_RUNTIME_DIR}/migrate.diff"
			;;
		[3uU]*)
			#update configversion automatically
			refversion="$(grep -e "^[#;]\\s*configversion\\s*[:=]" "$defaultfile" |  tr -d "\n")"
			if grep -qe "^[#;]\\s*configversion\\s*[:=].*" "$userfile"; then
				sed -i "s/^[#;]\\s*configversion\\s*[:=].*/$refversion/" "$userfile" || abort=1
			else
				# fall back in case the userfile doesn't contain a configversion at all yet
				sed -i "2i$refversion" "$userfile" || abort=1
			fi
			;;
		*)
			abort=1
			;;
	esac

	if [ "$abort" -eq 0 ]; then
		#finish the migration, removing .needs-migration and moving to right place
		case "$userfile" in
			*needs-migration)
				mv -f "$userfile" "${userfile%.needs-migration}"
				;;
		esac
	fi
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
		if [ ! -e "$userfile.needs-migration" ]; then
			mv "$userfile" "$userfile.needs-migration"
		else
			sxmo_log "$userfile was already flagged for needing migration; not overwriting the older one"
		fi
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
			[ -e "$hook" ] || continue #sanity check because shell enters loop even when there are no files in dir (null glob)
			if [ "$MODE" = "reset" ]; then
				if [ ! -e "$hook.needs-migration" ]; then
					mv "$hook" "$hook.needs-migration" #move the hook away
				else
					sxmo_log "$hook was already flagged for needing migration; not overwriting the older one"
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


#set default mode
[ -z "$*" ] && set -- interactive

#modes may be chained
for MODE in "$@"; do
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
done
