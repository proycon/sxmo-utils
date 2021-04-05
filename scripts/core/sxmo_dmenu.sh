#!/usr/bin/env sh

TERMMODE=$([ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] && echo "true")

if [ "$TERMMODE" != "true" ]; then
	exec dmenu "$@"
else
	exec vis-menu -i -l 10
fi
