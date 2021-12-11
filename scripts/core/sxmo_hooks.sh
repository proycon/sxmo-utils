#!/bin/sh

hook="$1"
shift

if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/$hook" ]; then
	exec "$XDG_CONFIG_HOME/sxmo/hooks/$hook" "$@"
elif [ -x "/usr/share/sxmo/default_hooks/$hook" ]; then
	exec "/usr/share/sxmo/default_hooks/$hook" "$@"
fi
