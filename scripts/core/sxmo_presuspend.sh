#!/usr/bin/env sh

# This script is called prior to suspending

# If this script returns a non-zero exit code, suspension will be cancelled

if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/presuspend" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/presuspend"
	exit $?
fi
