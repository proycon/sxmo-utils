#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh
. sxmo_common.sh

set -e

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

# adjust *output* vol/mute
pulsevolup() {
	cur_vol="$(pulsevolget)"
	[ "$cur_vol" = "muted" ] && return
	if [ "$cur_vol" -gt "$((100 - ${1:-5}))" ]; then
		pactl set-sink-volume @DEFAULT_SINK@ 100%
	else
		pactl set-sink-volume @DEFAULT_SINK@ +"${1:-5}%"
	fi
	pulsevolget | notifyvol -
}

pulsevoldown() {
	cur_vol="$(pulsevolget)"
	[ "$cur_vol" = "muted" ] && return
	if [ "$cur_vol" -lt "$((0 + ${1:-5}))" ]; then
		pactl set-sink-volume @DEFAULT_SINK@ 0%
	else
		pactl set-sink-volume @DEFAULT_SINK@ -"${1:-5}%"
	fi
	pulsevolget | notifyvol -
}

pulsevoltogglemute() {
	pactl set-sink-mute @DEFAULT_SINK@ toggle
	sxmo_hook_statusbar.sh volume
}

pulsevolismuted() {
	pactl get-sink-mute @DEFAULT_SINK@ | grep -q "Mute: yes"
}

pulsevolget() {
	if pulsevolismuted; then
		printf "muted"
	else
		pactl get-sink-volume @DEFAULT_SINK@ | head -n1 | cut -d'/' -f2 | sed 's/ //g' | sed 's/\%//'
	fi
}

pulsevolset() {
	pact set-sink-volume @DEFAULT_SINK@ "$1"%
	pulsevolget | notifyvol
}

# adjust *input* vol/mute
pulsemicvolup() {
	cur_vol="$(pulsemicvolget)"
	[ "$cur_vol" = "muted" ] && return
	if [ "$cur_vol" -gt "$((100 - ${1:-5}))" ]; then
		pactl set-source-volume @DEFAULT_SOURCE@ 100%
	else
		pactl set-source-volume @DEFAULT_SOURCE@ +"${1:-5}%"
	fi
	pulsemicvolget | notifyvol -
}

pulsemicvoldown() {
	cur_vol="$(pulsemicvolget)"
	[ "$cur_vol" = "muted" ] && return
	if [ "$cur_vol" -lt "$((0 + ${1:-5}))" ]; then
		pactl set-source-volume @DEFAULT_SOURCE@ 0%
	else
		pactl set-source-volume @DEFAULT_SOURCE@ -"${1:-5}%"
	fi
	pulsemicvolget | notifyvol -
}

pulsemictogglemute() {
	pactl set-source-mute @DEFAULT_SOURCE@ toggle
	sxmo_hook_statusbar.sh volume
}

pulsemicismuted() {
	pactl get-source-mute @DEFAULT_SOURCE@ | grep -q "Mute: yes"
}

pulsemicvolget() {
	if pulsemicismuted; then
		printf "muted"
	else
		pactl get-source-volume @DEFAULT_SOURCE@ | head -n1 | cut -d'/' -f2 | sed 's/ //g' | sed 's/\%//'
	fi
}

pulsemicvolset() {
	pact set-source-volume @DEFAULT_SOURCE@ "$1"%
	pulsevolget | notifyvol
}

# set the *active port* for output
pulsedeviceset() {
	pactl set-sink-port @DEFAULT_SINK@ "[Out] $1"
	sxmo_hook_statusbar.sh volume
}

# set the *active port* for input
pulsedevicesetinput() {
	pactl set-source-port @DEFAULT_SOURCE@ "[In] $1"
	sxmo_hook_statusbar.sh volume
}

# get the *active port* for input
pulsedevicegetinput() {
	[ -z "$1" ] && default_source="$(pactl get-default-source)" || default_source="$1"
	pactl --format=json list sources | jq -r ".[] | select(.name == \"$default_source\") | .active_port" | sed 's/\[In] //'
}

# get the *active port* for output
pulsedeviceget() {
	[ -z "$1" ] && default_sink="$(pactl get-default-sink)" || default_sink="$1"
	pactl --format=json list sinks | jq -r ".[] | select(.name == \"$default_sink\") | .active_port" | sed 's/\[Out] //'
}

# get the default sink
pulsedevicegetdefaultsink() {
	pactl get-default-sink
}

# get the default source
pulsedevicegetdefaultsource() {
	pactl get-default-source
}

pulsesourceset() {
	pactl set-default-source "$1"
}

pulsesinkset() {
	pactl set-default-sink "$1"
}

# get a list of sinks
_pulsesinkssubmenu() {
	[ -z "$1" ] && default_sink="$(pactl get-default-sink)" || default_sink="$1"
	pactl --format=json list sinks | jq -r '.[] | .name, .description' | while read -r line; do
		name="$line"
		read -r description
		if [ "$default_sink" = "$name" ]; then
			printf "%s %s %s ^ pulsesinkset %s\n" "$icon_chk" "$icon_spk" "$description" "$name"
		else
			printf "  %s %s ^ pulsesinkset %s\n" "$icon_spk" "$description" "$name"
		fi
	done
}

# get a list of output ports
_pulseoutportssubmenu() {
	[ -z "$1" ] && default_sink="$(pactl get-default-sink)" || default_sink="$1"
	active_out_port="$(pulsedeviceget "$default_sink")"
	pactl --format=json list sinks | jq -r ".[] | select(.name == \"$default_sink\" ) | .ports[] | select(.availability != \"not available\" ) | .name" | sed 's/\[Out] //' | while read -r line; do
		[ "$active_out_port" = "$line" ] && icon="$icon_ton" || icon="$icon_tof"
		printf "  %s %s ^ pulsedeviceset %s\n" "$icon" "$line" "$line"
	done
}

# get a list of input sources
_pulsesourcessubmenu() {
	[ -z "$1" ] && default_source="$(pactl get-default-source)" || default_source="$1"
	pactl --format=json list sources | jq -r '.[] | select (.monitor_source == "") | .name, .description' | while read -r line; do
		name="$line"
		read -r description
		if [ "$default_source" = "$name" ]; then
			printf "%s %s %s ^ pulsesourceset %s\n" "$icon_chk" "$icon_mic" "$description" "$name"
		else
			printf "  %s %s ^ pulsesourceset %s\n" "$icon_mic" "$description" "$name"
		fi
	done
}

# get a list of input ports
_pulseinportssubmenu() {
	# if the Headset is NOT plugged in, then do not display Headset
	# as a option, as clicking on it causes pulse to unset the source!!
	[ -z "$1" ] && default_source="$(pactl get-default-source)" || default_source="$1"
	active_in_port="$(pulsedevicegetinput "$default_source")"
	pactl --format=json list sources | jq -r ".[] | select(.name == \"$default_source\" ) | .ports[] | select(.availability != \"not available\" ) | .name" | sed 's/\[In] //' | while read -r line; do
		[ "$active_in_port" = "$line" ] && icon="$icon_ton" || icon="$icon_tof"
		printf "  %s %s ^ pulsedevicesetinput %s\n" "$icon" "$line" "$line"
	done
}

_callaudiodsubmenu() {
	if ! command -v callaudiocli > /dev/null; then
		return
	fi

	if sxmo_modemaudio.sh is_call_audio_mode; then
		printf "  %s callaudiod 'Call Mode' profile ^ sxmo_modemaudio.sh disable_call_audio_mode\n" "$icon_ton"
	else
		printf "  %s callaudiod 'Call Mode' profile ^ sxmo_modemaudio.sh enable_call_audio_mode\n" "$icon_tof"
	fi

}

_ringmodesubmenu() {
	if [ -f "$XDG_CONFIG_HOME"/sxmo/.noring ]; then
		printf " %s Ring ^ rm -f \"$XDG_CONFIG_HOME\"/sxmo/.noring\n" "$icon_tof"
	else
		printf " %s Ring ^ touch \"$XDG_CONFIG_HOME\"/sxmo/.noring\n" "$icon_ton"
	fi
	if [ -f "$XDG_CONFIG_HOME"/sxmo/.novibrate ]; then
		printf " %s Vibrate ^ rm -f \"$XDG_CONFIG_HOME\"/sxmo/.novibrate\n" "$icon_tof"
	else
		printf " %s Vibrate ^ touch \"$XDG_CONFIG_HOME\"/sxmo/.novibrate\n" "$icon_ton"
	fi
}

pulsemenuchoices() {
cur_vol="$(pulsevolget)"
cur_mic_vol="$(pulsemicvolget)"
default_sink_name="$(pulsedevicegetdefaultsink)"
default_source_name="$(pulsedevicegetdefaultsource)"
grep . <<EOF
Output:
$(_pulsesinkssubmenu "$default_sink_name")
$(
if [ "$cur_vol" != "muted" ]; then
	printf "  %s Volume (%s%%) ^ pulsevolup\n" "$icon_aru" "$cur_vol"
	printf "  %s Volume (%s%%) ^ pulsevoldown\n" "$icon_ard" "$cur_vol"
	printf "  %s Output Mute ^ pulsevoltogglemute\n" "$icon_tof"
else
	printf "  %s Output Mute ^ pulsevoltogglemute\n" "$icon_ton"
fi
)
$(_pulseoutportssubmenu "$default_sink_name")
Input:
$(_pulsesourcessubmenu "$default_source_name")
$(
if [ "$cur_mic_vol" != "muted" ]; then
	printf "  %s Volume (%s%%) ^ pulsemicvolup\n" "$icon_aru" "$cur_mic_vol"
	printf "  %s Volume (%s%%) ^ pulsemicvoldown\n" "$icon_ard" "$cur_mic_vol"
	printf "  %s Input Mute ^ pulsemictogglemute\n" "$icon_tof"
else
	printf "  %s Input Mute ^ pulsemictogglemute\n" "$icon_ton"
fi
)
$(_pulseinportssubmenu "$default_source_name")
Call Options:
$(_callaudiodsubmenu)
$(_ringmodesubmenu)
$icon_cls Close Menu  ^ exit
EOF
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

alsavolget() {
	if [ -n "$(alsacurrentdevice)" ]; then
		amixer -c "${SXMO_ALSA_CONTROL_NAME:-0}" get "$(alsacurrentdevice)" | amixerextractvol
	fi
}

alsamicismuted() {
	echo "Not implemented"
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
	type pactl > /dev/null 2>&1 || return 1
	pactl info > /dev/null 2>&1 || return 1
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

if [ "$backend" = "alsa" ]; then
	# set some alsa specific things
	SPEAKER="${SXMO_SPEAKER:-"Line Out"}"
	HEADPHONE="${SXMO_HEADPHONE:-"Headphone"}"
	EARPIECE="${SXMO_EARPIECE:-"Earpiece"}"
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
