#!/usr/bin/env sh

# This script (and anything it calls) should return as quickly as possible
# as it blocks the system from suspending (and processing input) until done

# If this script returns a non-zero exit code, the system will wake up

if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/rtcwake" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/rtcwake"
	exit $?
fi
