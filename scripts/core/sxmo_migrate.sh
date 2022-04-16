#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

. /etc/profile.d/sxmo_init.sh
_sxmo_load_environments

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
			export DIFFTOOL="${DIFFTOOL:-vimdiff}"
			if [ -n "$DIFFTOOL" ] && command -v "$DIFFTOOL" >/dev/null; then # ex vimdiff
				set -- "$DIFFTOOL" "$defaultfile" "$userfile"
			else
				diff -u "$defaultfile" "$userfile" > "${XDG_RUNTIME_DIR}/migrate.diff"
				set -- "$EDITOR" "$userfile" "$defaultfile" "${XDG_RUNTIME_DIR}/migrate.diff"
			fi

			if ! "$@"; then
				#user may bail editor, in which case we ignore everything
				abort=1
			fi

			if [ -z "$DIFFTOOL" ]; then
				rm "${XDG_RUNTIME_DIR}/migrate.diff"
			fi
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
	if ! [ -e "$XDG_CONFIG_HOME/sxmo/hooks/" ]; then
		return
	fi
	for hook in \
		"$XDG_CONFIG_HOME/sxmo/hooks/"* \
		${SXMO_DEVICE_NAME:+"$XDG_CONFIG_HOME/sxmo/hooks/$SXMO_DEVICE_NAME/"*}; do
		{ [ -e "$hook" ] && [ -f "$hook" ];} || continue #sanity check because shell enters loop even when there are no files in dir (null glob)

		if printf %s "$hook" | grep -q "/$SXMO_DEVICE_NAME/"; then
			# We also compare the device user hook to the system
			# default version
			DEFAULT_PATH="/usr/share/sxmo/default_hooks/$SXMO_DEVICE_NAME/:/usr/share/sxmo/default_hooks/"
		else
			# We dont want to compare a default user hook to the device
			# system version
			DEFAULT_PATH="/usr/share/sxmo/default_hooks/"
		fi

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
				defaulthook="$(PATH="$DEFAULT_PATH" command -v "$(basename "$hook" ".needs-migration")")"
				[ "$MODE" = sync ] && continue # ignore this already synced hook
				;;
			*.backup)
				#skip
				continue
				;;
			*)
				#if there is already one marked as needing migration, use that one instead and skip this one
				[ -e "$hook.needs-migration" ] && continue
				defaulthook="$(PATH="$DEFAULT_PATH" command -v "$(basename "$hook")")"
				;;
		esac
		if [ -f "$defaulthook" ]; then
			if diff "$hook" "$defaulthook" > /dev/null && [ "$MODE" != "sync" ]; then
				printf "\e[33mHook %s is identical to the default, so you don't need a custom hook, remove it? [y/N]\e[0m" "$hook"
				read -r reply < /dev/tty
				if [ "y" = "$reply" ]; then
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
				printf "\e[31mThe hook \e[32m%s\e[31m does not exist (anymore), remove it? [y/N] \e[0m\n" "$hook"
			) | more
			read -r reply < /dev/tty
			if [ "y" = "$reply" ]; then
				rm "$hook"
			fi
			printf "\n"
		fi
	done
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

# Don't allow running with sudo, or as root 
if [ -n "$SUDO_USER" ]; then
	echo "$0 can't be run with sudo, it must be run as your user" >&2
	exit 127
fi

if [ "$USER" = "root" ]; then
	echo "$0 can't be run as root, it must be run as your user" >&2
	exit 127
fi

# Execute idempotent migrations
find /usr/share/sxmo/migrations -type f | sort -n | tr '\n' '\0' | xargs -0 sh

#modes may be chained
for MODE in "$@"; do
	case "$MODE" in
		"interactive"|"all")
			common
			sway
			xorg
			checkhooks
			;;
		"sync"|"reset")
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
			NEED_MIGRATION="$(find "$XDG_CONFIG_HOME/" -name "*.needs-migration")"
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
