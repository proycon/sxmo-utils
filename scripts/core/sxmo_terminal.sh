#!/usr/bin/env sh

# shellcheck disable=SC2086
set -- $TERMCMD "$@"

if [ -z "$*" ]; then
	echo "sxmo_terminal.sh called in TERMMODE without any arguments (returning, nothing to do)" >&2
else
	exec "$@"
fi
