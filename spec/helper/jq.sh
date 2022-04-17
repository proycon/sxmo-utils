#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

jq -v | cut -d" " -f1
