#!/bin/sh

ROOT_DIR="$XDG_RUNTIME_DIR"/sxmo_playerctl
mkdir -p "$ROOT_DIR"
PAUSED_FILE="$ROOT_DIR"/paused

list_playing() {
	playerctl -l | while read -r player; do
		if playerctl -p "$player" status | grep -q Playing; then
			printf "%s\n" "$player"
		fi
	done
}

pause_all() {
	list_playing >> "$PAUSED_FILE"
	xargs -P10 -I{} -n1 playerctl -p "{}" pause < "$PAUSED_FILE"
}

resume_all() {
	[ ! -e "$PAUSED_FILE" ] && return
	xargs -P10 -I{} -n1 playerctl -p "{}" play < "$PAUSED_FILE"
	rm "$PAUSED_FILE"
}

if ! command -v playerctl >/dev/null; then
	return
fi

if ! playerctl status >/dev/null 2>&1; then
	return
fi

case "$1" in
	pause_all)
		pause_all
		;;
	resume_all)
		resume_all
		;;
esac
