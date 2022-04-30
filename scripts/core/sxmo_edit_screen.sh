#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors
tmpfile=$(mktemp /tmp/st-edit.XXXXXX)
trap  'rm "$tmpfile"' 0 1 15
cat > "$tmpfile"
# shellcheck disable=SC2086
sxmo_terminal.sh $EDITOR "$tmpfile"
