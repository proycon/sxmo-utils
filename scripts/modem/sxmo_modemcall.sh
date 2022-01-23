#!/bin/sh

ALSASTATEFILE="$XDG_CACHE_HOME"/precall.alsa.state
trap "gracefulexit" INT TERM

# include common definitions
# shellcheck source=scripts/core/sxmo_icons.sh
. "$(dirname "$0")/sxmo_icons.sh"
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

stderr() {
	sxmo_log "$*"
}

finish() {
	sxmo_vibratepine 1000 &
	if [ -f "$ALSASTATEFILE" ]; then
		alsactl --file "$ALSASTATEFILE" restore
	else
		alsactl --file /usr/share/sxmo/alsa/default_alsa_sound.conf restore
	fi
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
	mmcli -m any -o "$1" -K |
	grep call.properties.number |
	cut -d ':' -f2 |
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

toggleflag() {
	TOGGLEFLAG=$1
	shift
	FLAGS="$*"

	# TODO: why >&2 here?
	echo -- "$FLAGS" | grep -- "$TOGGLEFLAG" >&2 &&
		NEWFLAGS="$(echo -- "$FLAGS" | sed "s/$TOGGLEFLAG//g")" ||
		NEWFLAGS="$(echo -- "$FLAGS $TOGGLEFLAG")"

	NEWFLAGS="$(echo -- "$NEWFLAGS" | sed "s/--//g; s/  / /g")"

	# shellcheck disable=SC2086
	sxmo_megiaudioroute $NEWFLAGS
	echo -- "$NEWFLAGS"
}

toggleflagset() {
	FLAGS="$(toggleflag "$1" "$FLAGS")"
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
	if [ "$DIRECTION" = "outgoing" ]; then
		modem_cmd_errcheck -m any -o "$CALLID" --start
		touch "$XDG_RUNTIME_DIR/${CALLID}.initiatedcall" #this signals that we started this call
		log_event "call_start" "$CALLID"
		stderr "Started call $CALLID"
	elif [ "$DIRECTION" = "incoming" ]; then
		stderr "Invoking pickup hook (async)"
		sxmo_hooks.sh pickup &
		touch "$XDG_RUNTIME_DIR/${CALLID}.pickedupcall" #this signals that we picked this call up
											     #to other asynchronously running processes
		modem_cmd_errcheck -m any -o "$CALLID" --accept
		log_event "call_pickup" "$CALLID"
		stderr "Picked up call $CALLID"
	else
		finish "Couldn't initialize call with callid <$CALLID>; unknown direction <$DIRECTION>"
	fi
	alsactl --file "$ALSASTATEFILE" store
}

hangup() {
	CALLID="$1"
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

incallsetup() {
	DMENUIDX=0
	CALLID="$1"
	NUMBER="$(vid_to_number "$CALLID")"
	# E.g. There's some bug with the modem that' requires us to toggle the
	# DAI a few times before starting the call for it to kick in
	FLAGS=" "
	toggleflagset "-e"
	toggleflagset "-m"
	toggleflagset "-2"
	toggleflagset "-2"
	toggleflagset "-2"
}

incallmenuloop() {
	stderr "Current flags are $FLAGS"
	CHOICES="
		$icon_aru Volume up                                                          ^ sxmo_audio.sh vol up
		$icon_ard Volume down                                                          ^ sxmo_audio.sh vol down
		$icon_phn Earpiece $(echo -- "$FLAGS" | grep -q -- -e && echo "$icon_chk")            ^ toggleflagset -e
		$icon_mic Mic $(echo -- "$FLAGS" | grep -q -- -m && echo "$icon_chk")                 ^ toggleflagset -m
		$icon_itm Linejack $(echo -- "$FLAGS" | grep -q -- -h && echo "$icon_chk")            ^ toggleflagset -h
		$icon_itm Linemic  $(echo -- "$FLAGS" | grep -q -- -l && echo "$icon_chk")            ^ toggleflagset -l
		$icon_spk Speakerphone $(echo -- "$FLAGS" | grep -q -- -s && echo "$icon_chk")        ^ toggleflagset -s
		$icon_itm Echomic $(echo -- "$FLAGS" | grep -q -- -z && echo "$icon_chk")             ^ toggleflagset -z
		$icon_mus DTMF Tones                                                        ^ dtmfmenu $CALLID
		$icon_phx Hangup                                                            ^ hangup $CALLID
	"

	PICKED="$(
		echo "$CHOICES" |
			xargs -0 echo |
			cut -d'^' -f1 |
			sed '/^[[:space:]]*$/d' |
			awk '{$1=$1};1' |
			dmenu --index "$DMENUIDX" -p "$NUMBER"
	)" || hangup "$CALLID" # in case the menu is closed

	stderr "Picked is $PICKED"
	echo "$PICKED" | grep -Ev "."

	CMD="$(echo "$CHOICES" | grep "$PICKED" | cut -d'^' -f2)"
	DMENUIDX="$(printf "%s - 2" "$(echo "$CHOICES" | grep -n "$PICKED" | cut -d ':' -f1)" | bc)"
	stderr "Eval in call context: $CMD"
	eval "$CMD"
	incallmenuloop
}

dtmfmenu() {
	CALLID="$1"
	NUMS="0123456789*#ABCD"

	while true; do
		PICKED="$(
			echo "$NUMS" | grep -o . | sed '1 iReturn to Call Menu' |
			dmenu -p "DTMF Tone"
		)" || return
		echo "$PICKED" | grep -q "Return to Call Menu" && return
		modem_cmd_errcheck -m any -o "$CALLID" --send-dtmf="$PICKED"
	done
}

pickup() {
	acceptcall "$1"
	incallsetup "$1"
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
		printf %b "$icon_phn Pickup\n$icon_phx Hangup\n$icon_mut Mute\n" |
		dmenu -H "$pickup_height" -p "$CONTACTNAME"
	)" || exit

	if echo "$PICKED" | grep -q "Pickup"; then
		pickup "$1"
	elif echo "$PICKED" | grep -q "Hangup"; then
		hangup "$1"
	elif echo "$PICKED" | grep -q "Mute"; then
		mute "$1"
	fi
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
