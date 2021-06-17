#!/usr/bin/env sh
# shellcheck disable=SC2086

if [ -n "$TERMNAME" ]; then
	case "$TERMCMD" in
		"st -e")
			set -- st -T "$TERMNAME" -e "$@"
			;;
		*)
			printf "%s: '%s'\n" "Not implemented for TERMCMD" "$TERMCMD" >&2
			set -- $TERMCMD "$@"
	esac
else
	set -- $TERMCMD "$@"
fi

if [ -z "$*" ]; then
	echo "sxmo_terminal.sh called in TERMMODE without any arguments (returning, nothing to do)" >&2
else
	exec "$@"
fi
