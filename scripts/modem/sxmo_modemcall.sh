#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

set -e

vid_to_number() {
	mmcli -m any -o "$1" -K | \
		grep call.properties.number | \
		cut -d ':' -f2 | \
		tr -d  ' '
}

log_event() {
	EVT_HANDLE="$1"
	EVT_VID="$2"

	NUM="$(vid_to_number "$EVT_VID")"
	TIME="$(date +%FT%H:%M:%S%z)"

	mkdir -p "$SXMO_LOGDIR"
	printf %b "$TIME\t$EVT_HANDLE\t$NUM\n" >> "$SXMO_LOGDIR/modemlog.tsv"
}

pickup() {
	CALLID="$1"

	DIRECTION="$(
		mmcli --voice-status -o "$CALLID" -K |
		grep call.properties.direction |
		cut -d: -f2 |
		tr -d " "
	)"
	case "$DIRECTION" in
		outgoing)
			if ! mmcli -m any -o "$CALLID" --start; then
				sxmo_notify_user.sh --urgency=critical "We failed to start the call"
				return 1
			fi

			sxmo_notify_user.sh "Started call"
			touch "$XDG_RUNTIME_DIR/${CALLID}.initiatedcall"
			log_event "call_start" "$CALLID"
			;;
		incoming)
			sxmo_log "Invoking pickup hook (async)"
			sxmo_hook_pickup.sh &

			if ! mmcli -m any -o "$CALLID" --accept; then
				sxmo_notify_user.sh --urgency=critical "We failed to accept the call"
				return 1
			fi

			sxmo_notify_user.sh "Picked up call"
			touch "$XDG_RUNTIME_DIR/${CALLID}.pickedupcall"
			log_event "call_pickup" "$CALLID"
			;;
		*)
			sxmo_notify_user.sh --urgency=critical "Couldn't initialize call with callid <$CALLID>; unknown direction <$DIRECTION>"
			;;
	esac
}

hangup() {
	CALLID="$1"

	if [ -f "$XDG_RUNTIME_DIR/${CALLID}.pickedupcall" ]; then
		rm -f "$XDG_RUNTIME_DIR/${CALLID}.pickedupcall"
		touch "$XDG_RUNTIME_DIR/${CALLID}.hangedupcall"
		log_event "call_hangsxmo_hook_discard.shup" "$CALLID"

		sxmo_log "sxmo_modemcall: Invoking hangup hook (async)"
		sxmo_hook_hangup.sh &
	else
		#this call was never picked up and hung up immediately, so it is a discarded call
		touch "$XDG_RUNTIME_DIR/${CALLID}.discardedcall"
		log_event "call_discard" "$CALLID"

		sxmo_log "sxmo_modemcall: Invoking discard hook (async)"
		sxmo_hook_discard.sh &
	fi

	if ! mmcli -m any -o "$CALLID" --hangup; then
		sxmo_notify_user.sh --urgency=critical "We failed to hangup the call"
		return 1
	fi
}

# We shallow muted/blocked and terminated calls
list_active_calls() {
	mmcli -m any --voice-list-calls | \
		awk '$1=$1' | \
		grep -v terminated | \
		grep -v "No calls were found" | while read -r line; do
			CALLID="$(printf "%s\n" "$line" | awk '$1=$1' | cut -d" " -f1 | xargs basename)"
			if [ -e "$XDG_RUNTIME_DIR/${CALLID}.mutedring" ]; then
				continue # we shallow muted calls
			fi
			printf "%s\n" "$line"
	done
}

incall_menu() {
	# We have an active call
	while list_active_calls | grep -q . ; do
		CHOICES="$(cat <<EOF
$icon_cls Close menu                ^ exit
$icon_aru Volume up                 ^ sxmo_audio.sh vol up 20
$icon_ard Volume down               ^ sxmo_audio.sh vol down 20
$icon_rol Reset call audio          ^ sxmo_modemaudio.sh setup_audio
$icon_spk Speaker $(sxmo_modemaudio.sh is_enabled_speaker \
	&& printf "%s ^ sxmo_modemaudio.sh disable_speaker" "$icon_ton" \
	|| printf "%s ^ sxmo_modemaudio.sh enable_speaker" "$icon_tof"
)
$(
	list_active_calls | while read -r line; do
		CALLID="$(printf %s "$line" | cut -d" " -f1 | xargs basename)"
		NUMBER="$(vid_to_number "$CALLID")"
		CONTACT="$(sxmo_contacts.sh --name "$NUMBER")"
		[ "$CONTACT" = "???" ] && CONTACT="$NUMBER"
		case "$line" in
			*"(ringing-in)")
				# TODO switch to this call
				printf "%s Hangup %s ^ hangup %s\n" "$icon_phx" "$CONTACT" "$CALLID"
				printf "%s Mute %s ^ mute %s\n" "$icon_phx" "$CONTACT" "$CALLID"
				;;
			*"(held)")
				# TODO switch to this call
				printf "%s Hangup %s ^ hangup %s\n" "$icon_phx" "$CONTACT" "$CALLID"
				;;
			*)
				printf "%s DTMF Tones %s ^ dtmf_menu %s\n" "$icon_mus" "$CONTACT" "$CALLID"
				printf "%s Hangup %s ^ hangup %s\n" "$icon_phx" "$CONTACT" "$CALLID"
				;;
		esac
	done
)
EOF
	)"

		# Disabled cause no effect on pinephone
		# https://gitlab.com/mobian1/callaudiod/-/merge_requests/10
		# $icon_mic Mic $(sxmo_modemaudio.sh is_muted_mic \
		# 	&& printf "%s ^ sxmo_modemaudio.sh unmute_mic " "$icon_tof" \
		# 	|| printf "%s ^ sxmo_modemaudio.sh mute_mic" "$icon_ton"
		# )

		PICKED="$(
			printf "%s\n" "$CHOICES" |
				cut -d'^' -f1 |
				sxmo_dmenu.sh -i -p "Incall Menu"
		)" || exit

		sxmo_log "Picked is $PICKED"

		CMD="$(printf "%s\n" "$CHOICES" | grep "$PICKED" | cut -d'^' -f2)"

		sxmo_log "Eval in call context: $CMD"
		eval "$CMD" || exit 1
	done & # To be killeable
	wait
}

dtmf_menu() {
	CALLID="$1"

	sxmo_keyboard.sh close
	KEYBOARD_ARGS="-o -l dialer" sxmo_keyboard.sh open | \
		sxmo_splitchar | xargs -n1 printf "%s\n" | stdbuf -o0 grep '[0-9A-D*#]' | \
		xargs -r -I{} -n1 mmcli -m any -o "$CALLID" --send-dtmf="{}" &

	# Closed return to default menu
	if ! printf "Close Menu\n" | sxmo_dmenu.sh -i -p "DTMF Tone"; then
		sxmo_keyboard.sh close
	fi

	sxmo_keyboard.sh close
}

mute() {
	CALLID="$1"
	touch "$XDG_RUNTIME_DIR/${CALLID}.mutedring" #this signals that we muted this ring
	sxmo_log "Invoking mute_ring hook (async)"
	sxmo_hook_mute_ring.sh "$CONTACTNAME" &
	log_event "ring_mute" "$1"
}

incoming_call_menu() {
	NUMBER="$(vid_to_number "$1")"
	CONTACTNAME="$(sxmo_contacts.sh --name "$NUMBER")"
	[ "$CONTACTNAME" = "???" ] && CONTACTNAME="$NUMBER"

	if [ "$SXMO_WM" = "sway" ]; then
		pickup_height="40"
	else
		pickup_height="100"
	fi

	(
		PICKED="$(
			cat <<EOF | sxmo_dmenu.sh -i -H "$pickup_height" -p "$CONTACTNAME"
$icon_phn Pickup
$icon_phx Hangup
$icon_mut Mute
EOF
		)" || exit

		case "$PICKED" in
			"$icon_phn Pickup")
				if ! sxmo_modemaudio.sh setup_audio; then
					sxmo_notify_user.sh --urgency=critical "We failed to setup call audio"
					return 1
				fi

				if ! pickup "$1"; then
					sxmo_notify_user.sh --urgency=critical "We failed to pickup the call"
					sxmo_modemaudio.sh reset_audio
					return 1
				fi

				incall_menu
				;;
			"$icon_phx Hangup")
				hangup "$1"
				;;
			"$icon_mut Mute")
				mute "$1"
				;;
		esac
	) & # To be killeable
	wait
}

killed() {
	sxmo_dmenu.sh close
}
if [ "$1" = "incall_menu" ] || [ "$1" = "incoming_call_menu" ]; then
	trap 'killed' TERM INT
fi

"$@"
