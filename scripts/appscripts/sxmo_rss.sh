#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors
# title="$icon_rss RSS"
# include common definitions
# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

FETCHENABLED=1

if [ -f "$XDG_CONFIG_HOME/sxmo/sfeedrc" ]; then
	SFEEDCONF="$XDG_CONFIG_HOME/sxmo/sfeedrc"
elif [ -f "$HOME/.sfeed/sfeedrc" ]; then
	SFEEDCONF="$HOME/.sfeed/sfeedrc"
else
	SFEEDCONF=$(xdg_data_path sxmo/appcfg/sxmo_sfeedrc)
fi

. "$SFEEDCONF"

die() {
	echo "Error: $1"
	exit 1
}

tflt() {
	# Date with feature like "1 day ago" etc main reason
	# coreutils is a dep...
	TIME=$(eval date -d \""$TIMESPAN"\" +%s)
	cat | gawk "\$1 > $TIME"
}

prep_temp_folder_with_items() {
	mkdir -p "$FOLDER"
	rm -rf "${FOLDER:?}/*"
	cd "${sfeedpath:-$HOME/.sfeed/feeds}" || die "Could cd to ${sfeedpath:-$HOME/.sfeed/feeds}"
	for f in ./*; do
		fclean="$(basename "$f")"
		tflt < "$fclean" > "$FOLDER/$fclean"
		[ -s "$FOLDER/$fclean" ] || rm "${FOLDER:?}/$fclean"
	done
}

list_items() {
	cd "$FOLDER" || die "Couldn't cd to $FOLDER"
	printf %b "Close Menu\nChange Timespan\n"
	gawk -F'\t' '{print $1 " " substr(FILENAME, 3) " | " $2 ": " $3 " " $8}' ./* |\
	grep -E '^[0-9]{5}' |\
	sort -nk1 |\
	sort -r |\
	gawk -F' ' '{printf strftime("%y/%m/%d %H:%M",$1); $1=""; print $0}'
}


rsstimespanmenu() {
	CHOICE="Fetch"
	while [ "${CHOICE#Fetch}" != "$CHOICE" ]; do
		# Dmenu prompt for timespan
		CHOICES="
			Close Menu
			1 hour ago
			3 hours ago
			12 hours ago
			1 day ago
			2 day ago
			1970-01-01
			Fetch $([ "$FETCHENABLED" = "1" ] && echo "enabled $icon_chk" || echo "disabled (use cache)")
		"
		CHOICE="$(
			echo "$CHOICES" |
			sed '/^[[:space:]]*$/d' |
			awk '{$1=$1};1' |
			sxmo_dmenu.sh -p "RSS Timespan"
		)" || return 0

		case "$CHOICE" in
			"Close Menu") return 0 ;;
			"Fetch"*) [ "$FETCHENABLED" = 0 ] && FETCHENABLED=1 || FETCHENABLED=0 ;;
			*) TIMESPAN="$CHOICE" ;;
		esac
	done

	# Update Sfeed via sfeed_update (as long as user didn't request cached)
	[ $FETCHENABLED = 1 ] &&
		sxmo_terminal.sh sh -c "echo Fetching Feeds && sfeed_update $SFEEDCONF"

	rssreadmenu
}

rssreadmenu() {
	# Make folder like /tmp/sfeed_1_day_ago
	FOLDER="/tmp/sfeed_$(echo "$TIMESPAN" | sed 's/ /_/g')"
	prep_temp_folder_with_items
	TIMESPANABBR="$(
		echo "$TIMESPAN" |
		sed -e 's/ago//g' -e 's/hour\|hours/h/g' -e 's/day\|days/d/g' -e 's/\s//g'
	)"

	CHOICES="$(list_items)"
	DMENUIDX=1
	while true; do
		PICKED="$(printf %b "$CHOICES" |
			sxmo_dmenu.sh --index "$DMENUIDX" -p "RSS ($TIMESPANABBR)")" || return 0
		DMENUIDX="$(echo "$CHOICES" | grep -m1 -F -n "$PICKED" | cut -d ':' -f1)"

		case "$PICKED" in
			"Close Menu") return 0;;
			"Change Timespan")
				rsstimespanmenu
				CHOICES="$(list_items)"
				DMENUIDX=1
				;;
			*)
				# Check for one http or 2, as there can be a link and enclosure
				if [ "$(echo "$PICKED" | awk -F "http" '{print NF-1}')" = "1" ]; then
					URL="$(echo "$PICKED" | awk -F " " '{print $NF}')"
					sxmo_urlhandler.sh "$URL"
				else
					URL="$(echo "$PICKED" | grep "http" | awk -F ' ' '{print "Link " $(NF-1) "\nEnclosure " $NF}' | awk '($0){print} END{print "Close Menu"}' | sxmo_dmenu.sh)"
					case "$URL" in
						"Close Menu") return 0;;
						*)
							PLAY="$(echo "$URL" | awk -F " " '{print $NF}')"
							sxmo_urlhandler.sh "$PLAY"
							;;
					esac
				fi
				;;
		esac
	done
}

rsstimespanmenu
