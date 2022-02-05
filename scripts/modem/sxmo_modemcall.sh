#!/bin/sh

trap "gracefulexit" INT TERM

# include common definitions
# shellcheck source=scripts/core/sxmo_icons.sh
. "$(dirname "$0")/sxmo_icons.sh"
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

AUDIO_MODE=
ENABLED_SPEAKER=
MUTED_MIC=

stderr() {
	sxmo_log "$*"
}

finish() {
	sxmo_vibrate 1000 &
	setsid -f sh -c 'sleep 2; sxmo_hooks.sh statusbar call_duration'
	if [ -n "$1" ]; then
		stderr "$1"
		notify-send Call "$1"
	fi
	if [ -z "$LOCKALREADYRUNNING" ]; then
		sxmo_daemons.sh stop proximity_lock
	fi
	sxmo_dmenu.sh close
	exit 1
}

gracefulexit() {
	kill "$MAINPID"
	wait "$MAINPID"
	finish "Call ended"
}


modem_cmd_errcheck() {
	RES="$(mmcli "$@" 2>&1)"
	OK="$?"
	stderr "Command: mmcli $*"
	if [ "$OK" != 0 ]; then finish "Problem executing mmcli command!\n$RES"; fi
	echo "$RES"
}

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

acceptcall() {
	CALLID="$1"
	stderr "Attempting to initialize CALLID $CALLID"
	DIRECTION="$(
		mmcli --voice-status -o "$CALLID" -K |
		grep call.properties.direction |
		cut -d: -f2 |
		tr -d " "
	)"
	case "$DIRECTION" in
		outgoing)
			modem_cmd_errcheck -m any -o "$CALLID" --start
			touch "$XDG_RUNTIME_DIR/${CALLID}.initiatedcall" #this signals that we started this call
			log_event "call_start" "$CALLID"
			stderr "Started call $CALLID"
			;;
		incoming)
			stderr "Invoking pickup hook (async)"
			sxmo_hooks.sh pickup &
			touch "$XDG_RUNTIME_DIR/${CALLID}.pickedupcall" #this signals that we picked this call up
												     #to other asynchronously running processes
			modem_cmd_errcheck -m any -o "$CALLID" --accept
			log_event "call_pickup" "$CALLID"
			stderr "Picked up call $CALLID"
			;;
		*)
			finish "Couldn't initialize call with callid <$CALLID>; unknown direction <$DIRECTION>"
			;;
	esac

	unmute_mic
	enable_call_audio_mode
	disable_speaker
}

hangup() {
	CALLID="$1"

	disable_call_audio_mode
	enable_speaker

	if [ -f "$XDG_RUNTIME_DIR/${CALLID}.pickedupcall" ]; then
		rm -f "$XDG_RUNTIME_DIR/${CALLID}.pickedupcall"
		touch "$XDG_RUNTIME_DIR/${CALLID}.hangedupcall" #this signals that we hanged up this call to other asynchronously running processes
		log_event "call_hangup" "$CALLID"
	else
		#this call was never picked up and hung up immediately, so it is a discarded call
		touch "$XDG_RUNTIME_DIR/${CALLID}.discardedcall" #this signals that we discarded this call to other asynchronously running processes
		stderr "sxmo_modemcall: Invoking discard hook (async)"
		sxmo_hooks.sh discard &
		log_event "call_discard" "$CALLID"
	fi
	modem_cmd_errcheck -m any -o "$CALLID" --hangup
	finish "Call with $NUMBER terminated"
	exit 0
}

muted_mic() {
	[ "$MUTED_MIC" -eq 1 ]
}

mute_mic() {
	callaudiocli -u 0
	MUTED_MIC=1
}

unmute_mic() {
	callaudiocli -u 1
	MUTED_MIC=0
}

is_call_audio_mode() {
	[ call = "$AUDIO_MODE" ]
}

enable_call_audio_mode() {
	callaudiocli -m 1
	AUDIO_MODE=call
}

disable_call_audio_mode() {
	callaudiocli -m 0
	AUDIO_MODE=default
}

enabled_speaker() {
	[ "$ENABLED_SPEAKER" -eq 1 ]
}

enable_speaker() {
	callaudiocli -s 1
	ENABLED_SPEAKER=1
}

disable_speaker() {
	callaudiocli -s 0
	ENABLED_SPEAKER=0
}

incallmenuloop() {
	DMENUIDX=0
	NUMBER="$(vid_to_number "$1")"
	export AUDIO_BACKEND=alsa # We cant control volume with pulse
	while : ; do
		CHOICES="$(cat <<EOF
$icon_aru Volume up                                          ^ sxmo_audio.sh vol up
$icon_ard Volume down                                        ^ sxmo_audio.sh vol down
$(enabled_speaker \
	&& printf "%s Earpiece ^ disable_speaker" "$icon_phn" \
	|| printf "%s Speakerphone ^ enable_speaker" "$icon_spk"
)
$icon_mus DTMF Tones                                         ^ dtmfmenu $CALLID
$icon_phx Hangup                                             ^ hangup $CALLID
EOF
	)"

		# Disable cause doesnt have effect o_O
		# $(muted_mic \
		# 	&& printf "%s Unmute mic ^ unmute_mic" "$icon_spk" \
		# 	|| printf "%s Mute mic ^ mute_mic" "$icon_phn"
		# )

		PICKED="$(
			printf "%s\n" "$CHOICES" |
				cut -d'^' -f1 |
				dmenu --index "$DMENUIDX" -p "$NUMBER"
		)" || hangup "$CALLID" # in case the menu is closed

		stderr "Picked is $PICKED"

		CMD="$(printf "%s\n" "$CHOICES" | grep "$PICKED" | cut -d'^' -f2)"
		DMENUIDX="$(($(printf "%s\n" "$CHOICES" | grep -n "^$PICKED" | head -n+1 | cut -d: -f1) -1))"
		stderr "Eval in call context: $CMD"
		eval "$CMD"
	done
}

dtmfmenu() {
	CALLID="$1"

	sxmo_keyboard.sh close
	KEYBOARD_ARGS="-o -l dialer" sxmo_keyboard.sh open | \
		sxmo_splitchar | xargs -n1 printf "%s\n" | stdbuf -o0 grep '[0-9A-D*#]' | \
		xargs -r -I{} -n1 mmcli -m any -o "$CALLID" --send-dtmf="{}" &

	printf "Close Menu\n" | sxmo_dmenu.sh -p "DTMF Tone"

	sxmo_keyboard.sh close
}

pickup() {
	acceptcall "$1"
	incallmenuloop "$1"
}

mute() {
	CALLID="$1"
	touch "$XDG_RUNTIME_DIR/${CALLID}.mutedring" #this signals that we muted this ring
	stderr "Invoking mute_ring hook (async)"
	sxmo_hooks.sh mute_ring "$CONTACTNAME" &
	log_event "ring_mute" "$1"
	finish "Ringing with $NUMBER muted"
}

incomingcallmenu() {
	NUMBER="$(vid_to_number "$1")"
	CONTACTNAME="$(sxmo_contacts.sh --name "$NUMBER")"
	[ "$CONTACTNAME" = "???" ] && CONTACTNAME="$NUMBER"

	if [ "$SXMO_WM" = "sway" ]; then
		pickup_height="40"
	else
		pickup_height="100"
	fi

	PICKED="$(
		cat <<EOF | dmenu -H "$pickup_height" -p "$CONTACTNAME"
$icon_phn Pickup
$icon_phx Hangup
$icon_mut Mute
EOF
	)" || exit

	case "$PICKED" in
		"$icon_phn Pickup")
			pickup "$1"
			;;
		"$icon_phx Hangup")
			hangup "$1"
			;;
		"$icon_mut Mute")
			mute "$1"
			;;
	esac
	rm -f "$SXMO_NOTIFDIR/incomingcall_${1}_notification"* #there may be multiple actionable notification for one call
}

# do not duplicate proximity lock if already running
if sxmo_daemons.sh running proximity_lock -q; then
	LOCKALREADYRUNNING=1
else
	sxmo_daemons.sh start proximity_lock sxmo_proximitylock.sh
fi

"$@" &
MAINPID="$!"
wait $MAINPID
