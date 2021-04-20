#!/usr/bin/env sh

TERMMODE=$([ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] && echo "true")
if [ "$TERMMODE" = "true" ]; then
	exec vis-menu -i -l 10
fi

wasopen="$(sxmo_keyboard.sh isopen && echo "yes")"

sxmo_keyboard.sh open
OUTPUT="$(cat | dmenu "$@")"
exitcode=$?
[ -z "$wasopen" ] && sxmo_keyboard.sh close
echo "$OUTPUT"
exit $exitcode
