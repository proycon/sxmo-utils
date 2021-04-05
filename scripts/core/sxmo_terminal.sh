#!/usr/bin/env sh

TERMMODE=$([ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] && echo "true")

if [ "$TERMMODE" = "true" ]; then
	while [ "-e" != "$1" ] || [ 0 -eq $# ]; do
		shift
	done
	shift
else
	set -- st "$@"
fi

exec "$@"
