#!/usr/bin/env sh
RECDIR=~/Recordings
OLDAUDIOF="$(mktemp)"
alsactl --file "$OLDAUDIOF" store
mkdir -p "$RECDIR"

restoreaudio() {
	alsactl --file "$OLDAUDIOF" restore
}

record() {
	TEMPFILE="$(mktemp --suffix=.wav)"
	NOW="$(date '+%y%m%d_%H%M%S')"
	st -e arecord -vv -f cd -c 1 "$TEMPFILE"
	DUR="$(
		mediainfo "$TEMPFILE" | 
		grep ^Duration | 
		head -n1 | 
		cut -d: -f2 |
		tr -d " "
	)"
	FILENAME="${NOW}_${DUR}.wav"
	FILE="${RECDIR}/${FILENAME}"
	mv "$TEMPFILE" "$FILE"

	while true; do
		PICK="$(
			printf %b "
				Save: $FILENAME
				Playback: ($DUR)\n
				Delete Recording
			" |
			xargs -0 echo | sed '/^[[:space:]]*$/d' | awk '{$1=$1};1' |
			dmenu -p "$DUR" -fn Terminus-18 -c -l 10
		)"
		if echo "$PICK" | grep "Playback"; then
			restoreaudio
			st -e mpv -v "$FILE"
		elif echo "$PICK" | grep "Delete Recording"; then
			rm "$FILE"
			echo "File deleted." | dmenu -fn Terminus-18 -c -l 10
			return
		else
			return
		fi
	done
}

while true; do
	NRECORDINGS="$(ls -1 "$RECDIR" | wc -l)"
	OPTION="$(
		printf %b "Line Jack\nMicrophone\n($NRECORDINGS) Recordings\nClose Menu" |
		dmenu -fn Terminus-30 -c -p "Record" -l 20
	)"

	if [ "$OPTION" = "Line Jack" ]; then
		sxmo_megiaudioroute -l
		record
	elif [ "$OPTION" = "Microphone" ]; then
		sxmo_megiaudioroute -m
		record
	elif echo "$OPTION" | grep "Recordings$"; then
		restoreaudio
		sxmo_files.sh "$RECDIR"
	elif [ "$OPTION" = "Close Menu" ]; then
		restoreaudio
		exit 0
	fi
done
