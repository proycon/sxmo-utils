#!/usr/bin/env sh

# This script is called when the system has successfully woken up after sleep

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

sxmo_statusbarupdate.sh
pkill -CONT conky

(sleep 15 && sxmo_resetscaninterval.sh) &

if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/postwake" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/postwake"
fi
