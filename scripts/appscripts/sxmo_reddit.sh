#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors
# title="$icon_red Reddit"
# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

[ -z "$SXMO_SUBREDDITS" ] && SXMO_SUBREDDITS="pine64official pinephoneofficial unixporn postmarketos linux"

menu() {
	SUBREDDIT="$(
		printf %b "Close Menu\n$(echo "$SXMO_SUBREDDITS" | tr " " '\n')" |
		sxmo_dmenu.sh -p "Subreddit:"
	)" || exit 0
	[ "Close Menu" = "$SUBREDDIT" ] && exit 0

	REDDITRESULTS="$(
		reddit-cli "$SUBREDDIT" |
			grep -E '^((created_utc|ups|title|url):|===)' |
			sed -E 's/^(created_utc|ups|title|url):\s+/\t/g' |
			tr -d '\n' |
			sed 's/===/\n/g' |
			sed 's/^\t//g' |
			sort -t"$(printf '%b' '\t')" -rnk4 |
			awk -F'\t' '{ printf "%4s", $3; print " " $4 " " $1 " " $2 }'
	)"

	while true; do
		RESULT="$(
			printf %b "Close Menu\n$REDDITRESULTS" |
			sxmo_dmenu.sh
		)" || exit 0

		[ "Close Menu" = "$RESULT" ] && exit 0
		URL=$(echo "$RESULT" | awk -F " " '{print $NF}')

		sxmo_urlhandler.sh "$URL"
	done
}

menu
