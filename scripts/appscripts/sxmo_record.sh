#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors
# title="$icon_mic Record"
# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

[ -z "$SXMO_RECDIR" ] && SXMO_RECDIR="$XDG_DATA_HOME"/sxmo/recordings
mkdir -p "$SXMO_RECDIR"

getdur() {
	mediainfo "$1" |
	grep ^Duration |
	head -n1 |
	cut -d: -f2 |
	tr -d " " |
	sed -E 's/[0-9]+ms//'
}

record() {
	PRETTYNAME="$1"
	DEVICE="$2"
	CHANNELS="$3"

	TEMPFILE="$(mktemp --suffix=.wav)"
	NOW="$(date '+%y%m%d_%H%M%S')"
	sxmo_terminal.sh arecord -D plug:"$DEVICE" -vv -f cd -c "$CHANNELS" "$TEMPFILE"
	FILENAME="${NOW}_${PRETTYNAME}_$(getdur "$TEMPFILE").wav"
	FILE="${SXMO_RECDIR}/${FILENAME}"
	mv "$TEMPFILE" "$FILE"
	echo "$FILE"
}

recordconfirm() {
	FILE="$1"
	FILENAME="$(basename "$FILE")"
	DUR="$(getdur "$FILE")"

	while true; do
		PICK="$(
			printf %b "
				Save: $FILENAME
				Playback: ($DUR)\n
				Delete Recording
			" |
			xargs -0 echo | sed '/^[[:space:]]*$/d' | awk '{$1=$1};1' |
			sxmo_dmenu.sh -p "$DUR"
		)"

		case "$PICK" in
			"Playback: "*) sxmo_terminal.sh mpv -v "$FILE" ;;
			"Delete Recording")
				rm "$FILE"
				echo "File deleted." | sxmo_dmenu.sh
				return
				;;
			*) return ;;
		esac
	done
}


recordmenu() {
	while true; do
		NRECORDINGS="$(find "$SXMO_RECDIR" -type f | wc -l)"
		OPTIONS="
			Line Jack
			Microphone
			($NRECORDINGS) Recordings
			Close Menu
		"
		OPTION="$(
			printf %b "$OPTIONS" |
			xargs -0 echo |
			sed '/^[[:space:]]*$/d' |
			awk '{$1=$1};1' |
			sxmo_dmenu.sh -p "Record"
		)"

		case "$OPTION" in
			"Line Jack")
				OLDAUDIOF="$(mktemp)"
				alsactl --file "$OLDAUDIOF" store
				sxmo_megiaudioroute -l
				FILE="$(record line dsnoop 1)"
				alsactl --file "$OLDAUDIOF" restore
				recordconfirm "$FILE"
				;;
			"Microphone")
				OLDAUDIOF="$(mktemp)"
				alsactl --file "$OLDAUDIOF" store
				sxmo_megiaudioroute -m
				FILE="$(record mic dsnoop 1)"
				alsactl --file "$OLDAUDIOF" restore
				recordconfirm "$FILE"
				;;
			*"Recordings")
				sxmo_files.sh "$SXMO_RECDIR"
				;;
			*)
				exit 0
		esac
	done
}

if [ -z "$1" ]; then
	set -- recordmenu
fi

"$@"
