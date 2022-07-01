#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh

set -e

SPEAKER="${SXMO_SPEAKER:-"Line Out"}"
HEADPHONE="${SXMO_HEADPHONE:-"Headphone"}"
EARPIECE="${SXMO_EARPIECE:-"Earpiece"}"

notifyvol() {
	vol="$1"
	if [ "-" = "$vol" ]; then
		vol="$(cat)"
	fi
	if [ "muted" = "$vol" ]; then
		vol=0
	fi
	if [ "$SXMO_WM" = "sway" ] && [ -z "$SXMO_WOB_DISABLE" ]; then
		printf "%s\n" "$vol" > "$XDG_RUNTIME_DIR"/sxmo.wobsock
	else
		dunstify -r 999 "♫ Volume $vol"
	fi
	sxmo_hook_statusbar.sh volume
}

pulsevolup() {
	pamixer -i "${1:-5}" --get-volume | notifyvol -
}

pulsevoldown() {
	pamixer -d "${1:-5}" --get-volume | notifyvol -
}

pulsevoltogglemute() {
	pamixer -t --get-mute --get-volume | \
		sed -e 's/^true.*/0/' -e 's/^false //' | \
		notifyvol -
}

pulsemictogglemute() {
	pamixer -t --default-source --get-mute --get-volume | \
		sed -e 's/^true.*/0/' -e 's/^false //' | \
		notifyvol -
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

pulsesinksset() {
	pactl set-default-sink "$1"
}

pulsesinksget() {
	default_id="$(pamixer --get-default-sink | tail -n1 | cut -d" " -f1)"
	pamixer --list-sinks | tail -n+2 | while read -r id _ _ description; do
		eval description="$description"
		if [ "$default_id" = "$id" ]; then
			printf "%s %s ^ %s\n" "$icon_chk" "$description" "$id"
		else
			printf "%s ^ %s\n" "$description" "$id"
		fi
	done
}

_callaudiodsubmenu() {
	if ! command -v callaudiocli > /dev/null; then
		return
	fi

	printf "%s " "$icon_ear"
	if sxmo_modemaudio.sh is_call_audio_mode; then
		printf "Mode: Call -> Default ^ sxmo_modemaudio.sh disable_call_audio_mode\n"
	else
		printf "Mode: Default -> Call ^ sxmo_modemaudio.sh enable_call_audio_mode\n"
	fi

	printf "%s " "$icon_ear"
	if sxmo_modemaudio.sh is_enabled_speaker; then
		printf "Output: Speaker -> Earpiece ^ sxmo_modemaudio.sh disable_speaker\n"
	else
		printf "Output: Earpiece -> Speaker ^ sxmo_modemaudio.sh enable_speaker\n"
	fi

	printf "%s " "$icon_ear"
	if sxmo_modemaudio.sh is_muted_mic; then
		printf "Mic: Off -> On ^ sxmo_modemaudio.sh unmute_mic\n"
	else
		printf "Mic: On -> Off ^ sxmo_modemaudio.sh mute_mic\n"
	fi
}

_ringmodesubmenu() {
	curmode="$(cat "$XDG_CONFIG_HOME"/sxmo/.ringmode)"
	[ -z "$curmode" ] && curmode="Ring&Vibrate"

	if [ "$curmode" = "Ring&Vibrate" ]; then
		printf "%s" "$icon_chk"
	else
		printf "%s" "$icon_cls"
	fi
	# carefull, this one can easily match for the Ring one too
	# shellcheck disable=SC2016
	printf ' Mode Ring&vibrate ^ echo "" > "$XDG_CONFIG_HOME/sxmo/.ringmode"\n'

	if [ "$curmode" = Vibrate ]; then
		printf "%s" "$icon_chk"
	else
		printf "%s" "$icon_cls"
	fi
	# shellcheck disable=SC2016
	printf ' Mode Vibrate ^ echo Vibrate > "$XDG_CONFIG_HOME/sxmo/.ringmode"\n'

	if [ "$curmode" = Ring ]; then
		printf "%s" "$icon_chk"
	else
		printf "%s" "$icon_cls"
	fi
	# shellcheck disable=SC2016
	printf ' Mode Ring ^ echo Ring > "$XDG_CONFIG_HOME/sxmo/.ringmode"\n'

	if [ "$curmode" = Mute ]; then
		printf "%s" "$icon_chk"
	else
		printf "%s" "$icon_cls"
	fi
	# shellcheck disable=SC2016
	printf ' Mode Muted ^ echo Mute > "$XDG_CONFIG_HOME/sxmo/.ringmode"\n'
}

pulsemenuchoices() {
	grep . <<EOF
$icon_cls Close Menu  ^ exit
$icon_aru Volume up   ^ pulsevolup
$icon_ard Volume down ^ pulsevoldown
$(pulsesinksget | sed -e "s/^/$icon_spk /" -e 's/\^ \([0-9]\+\)$/^ pulsesinksset \1/')
$(_callaudiodsubmenu)
$(_ringmodesubmenu)
EOF
}

alsadetectdevice() {
	for DEVICE in "$EARPIECE" "$HEADPHONE" "$SPEAKER"; do
		if amixer -c "${SXMO_ALSA_CONTROL_NAME:-0}" sget "$DEVICE" | grep -qE '\[on\]'; then
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
	amixer -c "${SXMO_ALSA_CONTROL_NAME:-0}" set "$(alsacurrentdevice)" "${1:-5}%+" | amixerextractvol | notifyvol -
}

alsavoldown() {
	amixer -c "${SXMO_ALSA_CONTROL_NAME:-0}" set "$(alsacurrentdevice)" "${1:-5}%-" | amixerextractvol | notifyvol -
}

alsavolset() {
	amixer -c "${SXMO_ALSA_CONTROL_NAME:-0}" set "$(alsacurrentdevice)" "$1%" | amixerextractvol | notifyvol -
}

alsavolget() {
	if [ -n "$(alsacurrentdevice)" ]; then
		amixer -c "${SXMO_ALSA_CONTROL_NAME:-0}" get "$(alsacurrentdevice)" | amixerextractvol
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
	amixer -c "${SXMO_ALSA_CONTROL_NAME:-0}" set "$SPEAKER" mute >/dev/null
	amixer -c "${SXMO_ALSA_CONTROL_NAME:-0}" set "$HEADPHONE" mute >/dev/null
	amixer -c "${SXMO_ALSA_CONTROL_NAME:-0}" set "$EARPIECE" mute >/dev/null

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
		amixer -c "${SXMO_ALSA_CONTROL_NAME:-0}" set "$DEV" unmute >/dev/null
	fi
	printf '%s' "$DEV" > "$XDG_RUNTIME_DIR/sxmo.audiocurrentdevice"

	sxmo_hook_statusbar.sh volume
}

alsamenuchoices() {
	CURRENTDEV="$(alsacurrentdevice)"
	cat <<EOF
$icon_cls Close Menu                                                        ^ exit
$icon_hdp Headphones $([ "$CURRENTDEV" = "Headphone" ] && echo "$icon_chk") ^ alsadeviceset Headphones
$icon_spk Speaker $([ "$CURRENTDEV" = "Line Out" ] && echo "$icon_chk")     ^ alsadeviceset Speaker
$icon_phn Earpiece $([ "$CURRENTDEV" = "Earpiece" ] && echo "$icon_chk")    ^ alsadeviceset Earpiece
$icon_mut None $([ -z "$CURRENTDEV" ] && echo "$icon_chk")                  ^ alsadeviceset
$icon_aru Volume up                                                         ^ alsavolup
$icon_ard Volume down                                                       ^ alsavoldown
$(_ringmodesubmenu)
EOF
}

ispulse() {
	type pamixer > /dev/null 2>&1 || return 1
	pamixer --list-sinks > /dev/null 2>&1 || return 1
}

if [ -z "$*" ]; then
	set -- menu
fi

backend="$AUDIO_BACKEND"
if [ -z "$backend" ]; then
	if ispulse; then
		backend=pulse
	else
		backend=alsa
	fi
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
	mic)
		verb="$1"
		shift
		"$backend"mic"$verb" "$@"
		;;
	device)
		verb="$1"
		shift
		"$backend"device"$verb" "$1"
		;;
esac
