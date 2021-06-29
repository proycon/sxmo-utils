#!/usr/bin/env sh
ALSASTATEFILE="$XDG_CACHE_HOME"/precall.alsa.state
trap "gracefulexit" INT TERM

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

modem_n() {
	MODEMS="$(mmcli -L)"
	echo "$MODEMS" | grep -qoE 'Modem\/([0-9]+)' || finish "Couldn't find modem - is your modem enabled?"
	echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
}


finish() {
	sxmo_vibratepine 1000 &
	if [ -f "$ALSASTATEFILE" ]; then
		alsactl --file "$ALSASTATEFILE" restore
	else
		alsactl --file /usr/share/sxmo/alsa/default_alsa_sound.conf restore
	fi
	setsid -f sh -c 'sleep 2; sxmo_statusbarupdate.sh'
	if [ -n "$1" ]; then
		echo "sxmo_modemcall: $1">&2
		notify-send "$1"
	fi
	[ -n "$LOCKPID" ] && kill "$LOCKPID"
	pkill -9 dmenu
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
	echo "sxmo_modemcall: Command: mmcli $*">&2
	if [ "$OK" != 0 ]; then finish "Problem executing mmcli command!\n$RES"; fi
	echo "$RES"
}

vid_to_number() {
	mmcli -m "$(modem_n)" -o "$1" -K |
	grep call.properties.number |
	cut -d ':' -f2 |
	tr -d  ' '
}

number_to_contactname() {
	NUMBER="$1"
	CONTACT=$(sxmo_contacts.sh --all |
		grep "^$NUMBER:" |
		cut -d':' -f 2 |
		sed 's/^[ \t]*//;s/[ \t]*$//' #strip leading/trailing whitespace
	)
	if [ -n "$CONTACT" ]; then
		echo "$CONTACT"
	else
		echo "Unknown ($NUMBER)"
	fi
}

log_event() {
	EVT_HANDLE="$1"
	EVT_VID="$2"
	NUM="$(vid_to_number "$EVT_VID")"
	TIME="$(date --iso-8601=seconds)"
	mkdir -p "$LOGDIR"
	printf %b "$TIME\t$EVT_HANDLE\t$NUM\n" >> "$LOGDIR/modemlog.tsv"
}

toggleflag() {
	TOGGLEFLAG=$1
	shift
	FLAGS="$*"

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
	echo "sxmo_modemcall: Attempting to initialize CALLID $CALLID">&2
	DIRECTION="$(
		mmcli --voice-status -o "$CALLID" -K |
		grep call.properties.direction |
		cut -d: -f2 |
		tr -d " "
	)"
	if [ "$DIRECTION" = "outgoing" ]; then
		modem_cmd_errcheck -m "$(modem_n)" -o "$CALLID" --start
		touch "$CACHEDIR/${CALLID}.initiatedcall" #this signals that we started this call
		log_event "call_start" "$CALLID"
		echo "sxmo_modemcall: Started call $CALLID">&2
	elif [ "$DIRECTION" = "incoming" ]; then
		echo "sxmo_modemcall: Invoking pickup hook (async)">&2
		sxmo_hooks.sh pickup &
		touch "$CACHEDIR/${CALLID}.pickedupcall" #this signals that we picked this call up
											     #to other asynchronously running processes
		modem_cmd_errcheck -m "$(modem_n)" -o "$CALLID" --accept
		log_event "call_pickup" "$CALLID"
		echo "sxmo_modemcall: Picked up call $CALLID">&2
	else
		finish "Couldn't initialize call with callid <$CALLID>; unknown direction <$DIRECTION>"
	fi
	alsactl --file "$ALSASTATEFILE" store
}

hangup() {
	CALLID="$1"
	if [ -f "$CACHEDIR/${CALLID}.pickedupcall" ]; then
		rm -f "$CACHEDIR/${CALLID}.pickedupcall"
		touch "$CACHEDIR/${CALLID}.hangedupcall" #this signals that we hanged up this call to other asynchronously running processes
		log_event "call_hangup" "$CALLID"
	else
		#this call was never picked up and hung up immediately, so it is a discarded call
		touch "$CACHEDIR/${CALLID}.discardedcall" #this signals that we discarded this call to other asynchronously running processes
		echo "sxmo_modemcall: Invoking discard hook (async)">&2
		sxmo_hooks.sh discard &
		log_event "call_discard" "$CALLID"
	fi
	modem_cmd_errcheck -m "$(modem_n)" -o "$CALLID" --hangup
	finish "Call with $NUMBER terminated"
	exit 0
}

togglewindowify() {
	if [ "$WINDOWIFIED" = "0" ]; then
		WINDOWIFIED=1
	else
		WINDOWIFIED=0
	fi
}

incallsetup() {
	DMENUIDX=0
	CALLID="$1"
	NUMBER="$(vid_to_number "$CALLID")"
	WINDOWIFIED=0
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
	echo "sxmo_modemcall: Current flags are $FLAGS">&2
	CHOICES="
		$([ "$WINDOWIFIED" = 0 ] && echo "$icon_wn2 Windowify" || echo "$icon_wn2 Unwindowify")   ^ togglewindowify
		$([ "$WINDOWIFIED" = 0 ] && echo "$icon_lck Screenlock                      ^ togglewindowify; sxmo_screenlock.sh lock &")
		$icon_aru Volume up                                                          ^ sxmo_vol.sh up
		$icon_ard Volume down                                                          ^ sxmo_vol.sh down
		$icon_phn Earpiece $(echo -- "$FLAGS" | grep -q -- -e && echo "$icon_chk")            ^ toggleflagset -e
		$icon_mic Mic $(echo -- "$FLAGS" | grep -q -- -m && echo "$icon_chk")                 ^ toggleflagset -m
		$icon_itm Linejack $(echo -- "$FLAGS" | grep -q -- -h && echo "$icon_chk")            ^ toggleflagset -h
		$icon_itm Linemic  $(echo -- "$FLAGS" | grep -q -- -l && echo "$icon_chk")            ^ toggleflagset -l
		$icon_spk Speakerphone $(echo -- "$FLAGS" | grep -q -- -s && echo "$icon_chk")        ^ toggleflagset -s
		$icon_itm Echomic $(echo -- "$FLAGS" | grep -q -- -z && echo "$icon_chk")             ^ toggleflagset -z
		$icon_mus DTMF Tones                                                        ^ dtmfmenu $CALLID
		$icon_phx Hangup                                                            ^ hangup $CALLID
	"

	pkill -9 dmenu # E.g. just incase user is playing with btns or hits a menu by mistake
	echo "$CHOICES" |
		xargs -0 echo |
		cut -d'^' -f1 |
		sed '/^[[:space:]]*$/d' |
		awk '{$1=$1};1' | #this cryptic statement trims leading/trailing whitespace from a string
		dmenu -idx $DMENUIDX -l 14 "$([ "$WINDOWIFIED" = 0 ] && echo "-c" || echo "-wm")" -p "$NUMBER" |
		(
			PICKED="$(cat)";
			echo "sxmo_modemcall: Picked is $PICKED">&2
			echo "$PICKED" | grep -Ev "."
			CMD=$(echo "$CHOICES" | grep "$PICKED" | cut -d'^' -f2)
			DMENUIDX=$(echo "$(echo "$CHOICES" | grep -n "$PICKED" | cut -d ':' -f1)" - 1 | bc)
			echo "sxmo_modemcall: Eval in call context: $CMD">&2
			eval "$CMD"
			incallmenuloop
		) & wait # E.g. bg & wait to allow for SIGINT propogation
}

dtmfmenu() {
	CALLID="$1"
	DTMFINDEX=0
	NUMS="0123456789*#ABCD"

	while true; do
		PICKED="$(
			echo "$NUMS" | grep -o . | sed '1 iReturn to Call Menu' |
			dmenu "$([ "$WINDOWIFIED" = 0 ] && echo "-c" || echo "-wm")" -l 20 -c -idx $DTMFINDEX -p "DTMF Tone"
		)"
		echo "$PICKED" | grep "Return to Call Menu" && return
		DTMFINDEX=$(echo "$NUMS" | grep -bo "$PICKED" | cut -d: -f1 | xargs -IN echo 2+N | bc)
		modem_cmd_errcheck -m "$(modem_n)" -o "$CALLID" --send-dtmf="$PICKED"
	done
}

pickup() {
	acceptcall "$1"
	incallsetup "$1"
	incallmenuloop "$1"
}

mute() {
	touch "$CACHEDIR/$1.mutedring" #this signals that we muted this ring
	echo "sxmo_modemmonitor: Invoking mute_ring hook (async)">&2
	sxmo_hooks.sh mute_ring "$CONTACTNAME" &
	log_event "ring_mute" "$1"
	finish "Ringing with $NUMBER muted"
}

incomingcallmenu() {
	NUMBER=$(vid_to_number "$1")
	CONTACTNAME=$(number_to_contactname "$NUMBER")

	PICKED="$(
		printf %b "$icon_phn Pickup\n$icon_phx Hangup\n$icon_mut Mute\n" |
		dmenu -c -l 5 -p "$CONTACTNAME"
	)"

	if echo "$PICKED" | grep -q "Pickup"; then
		pickup "$1"
	elif echo "$PICKED" | grep -q "Hangup"; then
		hangup "$1"
	elif echo "$PICKED" | grep -q "Mute"; then
		mute "$1"
	fi
	rm -f "$NOTIFDIR/incomingcall_${1}_notification"* #there may be multiple actionable notification for one call
}

modem_n || finish "Couldn't determine modem number - is modem online?"

# do not duplicate proximity lock if already running
if ! pgrep -f sxmo_proximitylock.sh > /dev/null; then
	sxmo_proximitylock.sh &
	LOCKPID="$!"
fi

"$@" &
MAINPID="$!"
wait $MAINPID
