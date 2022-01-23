#!/bin/sh

# shellcheck source=scripts/core/sxmo_icons.sh
. "$(which sxmo_icons.sh)"

set -e

SPEAKER="${SPEAKER:-"Line Out"}"
HEADPHONE="${HEADPHONE:-"Headphone"}"
EARPIECE="${EARPIECE:-"Earpiece"}"

notifyvol() {
	vol="$1"
	if [ "-" = "$vol" ]; then
		vol="$(cat)"
	fi
	if [ "muted" = "$vol" ]; then
		vol=0
	fi
	case "$SXMO_WM" in
		sway)
			printf "%s\n" "$vol" > "$XDG_RUNTIME_DIR"/sxmo.wobsock
			;;
		*)
			notify-send "♫ Volume" "$vol"
			;;
	esac
	sxmo_hooks.sh statusbar volume
}

pulsevolup() {
	pamixer -i 5 --get-volume | notifyvol -
}

pulsevoldown() {
	pamixer -d 5 --get-volume | notifyvol -
}

pulsevolget() {
	pamixer --get-volume
}

pulsevolset() {
	pamixer --set-volume "$1" --get-volume | notifyvol -
}

pulsedeviceset() {
	printf "Not implemented\n" >&2
}

pulsedeviceget() {
	printf "Not implemented\n" >&2
}

pulsemenuchoices() {
	cat <<EOF
$icon_cls Close Menu  ^ exit
$icon_aru Volume up   ^ pulsevolup
$icon_ard Volume down ^ pulsevoldown
EOF
}

alsadetectdevice() {
	for DEVICE in "$EARPIECE" "$HEADPHONE" "$SPEAKER"; do
		if amixer -c 0 sget "$DEVICE" | grep -qE '\[on\]'; then
			printf %s "$DEVICE"
			return
		fi
	done
}

alsacurrentdevice() {
	if ! [ -f "$XDG_RUNTIME_DIR"/sxmo.audiocurrentdevice ]; then
		alsadeviceset "$SPEAKER"
		printf %s "$SPEAKER" > "$XDG_RUNTIME_DIR"/sxmo.audiocurrentdevice
	fi

	cat "$XDG_RUNTIME_DIR"/sxmo.audiocurrentdevice
}

amixerextractvol() {
	grep -oE '([0-9]+)%' |
		tr -d ' %' |
		awk '{ s += $1; c++ } END { print s/c }'  |
		xargs printf %.0f
}

alsavolup() {
	amixer -c 0 set "$(alsacurrentdevice)" "5%+" | amixerextractvol | notifyvol -
}

alsavoldown() {
	amixer -c 0 set "$(alsacurrentdevice)" "5%-" | amixerextractvol | notifyvol -
}

alsavolset() {
	amixer -c 0 set "$(alsacurrentdevice)" "$1%" | amixerextractvol | notifyvol -
}

alsavolget() {
	if [ -n "$(alsacurrentdevice)" ]; then
		amixer -c 0 get "$(alsacurrentdevice)" | amixerextractvol
	fi
}

alsadeviceget() {
	case "$(alsacurrentdevice)" in
		"$SPEAKER")
			printf "Speaker"
			;;
		"$HEADPHONE")
			printf "Headphone"
			;;
		"$EARPIECE")
			printf "Earpiece"
			;;
	esac
}

alsadeviceset() {
	amixer -c 0 set "$SPEAKER" mute >/dev/null
	amixer -c 0 set "$HEADPHONE" mute >/dev/null
	amixer -c 0 set "$EARPIECE" mute >/dev/null

	case "$1" in
		Speaker|speaker)
			DEV="$SPEAKER"
			;;
		Headphones|headphones)
			DEV="$HEADPHONE"
			;;
		Earpiece|earpiece)
			DEV="$EARPIECE"
			;;
		*)
			DEV=""
			;;
	esac
	if [ "$DEV" ]; then
		amixer -c 0 set "$DEV" unmute >/dev/null
	fi
	printf '%s' "$DEV" > "$XDG_RUNTIME_DIR/sxmo.audiocurrentdevice"

	sxmo_hooks.sh statusbar volume
}

alsamenu() {
	cat <<EOF
$icon_cls Close Menu                                                        ^ exit
$icon_hdp Headphones $([ "$CURRENTDEV" = "Headphone" ] && echo "$icon_chk") ^ alsadeviceset Headphones
$icon_spk Speaker $([ "$CURRENTDEV" = "Line Out" ] && echo "$icon_chk")     ^ alsadeviceset Speaker
$icon_phn Earpiece $([ "$CURRENTDEV" = "Earpiece" ] && echo "$icon_chk")    ^ alsadeviceset Earpiece
$icon_mut None $([ -z "$CURRENTDEV" ] && echo "$icon_chk")                  ^ alsadeviceset
$icon_aru Volume up                                                         ^ alsavolup
$icon_ard Volume down                                                       ^ alsavoldown
EOF
}

ispulse() {
	type pamixer > /dev/null 2>&1 || return 1
	pamixer --list-sinks > /dev/null 2>&1 || return 1
}

if [ -z "$*" ]; then
	set -- menu
fi

if ispulse; then
	backend=pulse
else
	backend=alsa
fi

cmd="$1"
shift
case "$cmd" in
	menu)
		while : ; do
			CHOICES="$("$backend"menuchoices)"
			PICKED="$(
				printf "%s\n" "$CHOICES" |
					cut -d'^' -f1 |
					sxmo_dmenu.sh -i -p "Audio"
			)"

			CMD="$(printf "%s\n" "$CHOICES" | grep -m1 -F "$PICKED" | cut -d '^' -f2)"

			eval "$CMD"
		done
		;;
	vol)
		verb="$1"
		shift
		"$backend"vol"$verb" "$@"
		;;
	device)
		verb="$1"
		shift
		"$backend"device"$verb" "$1"
		;;
esac
