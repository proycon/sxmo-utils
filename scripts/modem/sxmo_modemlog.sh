#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

st -f "Terminus-14" -e tail -n9999 -f "$LOGDIR"/modemlog.tsv
