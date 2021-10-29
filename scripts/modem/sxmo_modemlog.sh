#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

sxmo_terminal.sh sh -c "tail -n9999 -f $LOGDIR/modemlog.tsv"
