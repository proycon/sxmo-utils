#!/usr/bin/env sh
LOGDIR="$XDG_CONFIG_HOME"/sxmo/modem
trap "gracefulexit" INT TERM

modem_n() {
	MODEMS="$(mmcli -L)"
	echo "$MODEMS" | grep -qoE 'Modem\/([0-9]+)' || fatalerr "Couldn't find modem - is your modem enabled?"
	echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
}


fatalerr() {
	# E.g. hangup all calls, switch back to default audio, notify user, and die
	sxmo_vibratepine 1000 &
	mmcli -m "$(modem_n)" --voice-hangup-all
	for CALLID in $(
		mmcli -m "$(modem_n)" --voice-list-calls | grep -oE "Call\/[0-9]+" | cut -d'/' -f2
	); do
		mmcli -m "$(modem_n)" --voice-delete-call "$CALLID"
	done
	alsactl --file /usr/share/sxmo/alsa/default_alsa_sound.conf restore
	notify-send "$1"
	setsid -f sh -c 'sleep 2; sxmo_statusbarupdate.sh'
	kill -9 0
}

gracefulexit() {
	fatalerr "Terminated via SIGTERM/SIGINT"
}


modem_cmd_errcheck() {
	RES="$(mmcli "$@" 2>&1)"
	OK="$?"
	echo "Command: mmcli $*"
	if [ "$OK" != 0 ]; then fatalerr "Problem executing mmcli command!\n$RES"; fi
	echo "$RES"
}

vid_to_number() {
	mmcli -m "$(modem_n)" -o "$1" -K | 
	grep call.properties.number | 
	cut -d ':' -f2 | 
	tr -d  ' +'
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
	echo "Attempting to initialize CALLID $CALLID"
	DIRECTION="$(
		mmcli --voice-status -o "$CALLID" -K |
		grep call.properties.direction |
		cut -d: -f2 |
		tr -d " "
	)"
	if [ "$DIRECTION" = "outgoing" ]; then
		modem_cmd_errcheck -m "$(modem_n)" -o "$CALLID" --start
		log_event "call_start" "$CALLID"
	elif [ "$DIRECTION" = "incoming" ]; then
		modem_cmd_errcheck -m "$(modem_n)" -o "$CALLID" --accept
		log_event "call_pickup" "$CALLID"
	else
		fatalerr "Couldn't initialize call with callid <$CALLID>; unknown direction <$DIRECTION>"
	fi
}

hangup() {
	CALLID="$1"
	modem_cmd_errcheck -m "$(modem_n)" -o "$CALLID" --hangup
	log_event "call_hangup" "$CALLID"
	fatalerr "Call with $NUMBER terminated"
	exit 1
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

incallmonitor() {
	CALLID="$1"
	while true; do
		sxmo_statusbarupdate.sh
		if mmcli -m "$(modem_n)" -K -o "$CALLID" | grep -E "^call.properties.state.+terminated"; then
			fatalerr "Call with $NUMBER terminated"
		fi
		echo "Call still in progress"
		sleep 3
	done
}

incallmenuloop() {
	echo "Current flags are $FLAGS"
	CHOICES="
		$([ "$WINDOWIFIED" = 0 ] && echo Windowify || echo Unwindowify)   ^ togglewindowify
		$([ "$WINDOWIFIED" = 0 ] && echo 'Screenlock                      ^ togglewindowify; sxmo_screenlock &')
		Volume ↑                                                          ^ sxmo_vol.sh up
		Volume ↓                                                          ^ sxmo_vol.sh down
		Earpiece $(echo -- "$FLAGS" | grep -q -- -e && echo ✓)            ^ toggleflagset -e
		Mic $(echo -- "$FLAGS" | grep -q -- -m && echo ✓)                 ^ toggleflagset -m
		Linejack $(echo -- "$FLAGS" | grep -q -- -h && echo ✓)            ^ toggleflagset -h
		Linemic  $(echo -- "$FLAGS" | grep -q -- -l && echo ✓)            ^ toggleflagset -l
		Speakerphone $(echo -- "$FLAGS" | grep -q -- -s && echo ✓)        ^ toggleflagset -s
		Echomic $(echo -- "$FLAGS" | grep -q -- -z && echo ✓)             ^ toggleflagset -z
		DTMF Tones                                                        ^ dtmfmenu $CALLID
		Hangup                                                            ^ hangup $CALLID
	"
	echo "$CHOICES" | 
		xargs -0 echo | 
		cut -d'^' -f1 | 
		sed '/^[[:space:]]*$/d' |
		awk '{$1=$1};1' |
		dmenu -idx $DMENUIDX -l 14 "$([ "$WINDOWIFIED" = 0 ] && echo "-c" || echo "-wm")" -fn "Terminus-30" -p "$NUMBER" |
		(
			PICKED="$(cat)";
			echo "Picked is $PICKED"
			echo "$PICKED" | grep -Ev "."
			CMD=$(echo "$CHOICES" | grep "$PICKED" | cut -d'^' -f2)
			DMENUIDX=$(echo "$(echo "$CHOICES" | grep -n "$PICKED" | cut -d ':' -f1)" - 1 | bc)
			echo "Eval in call context: $CMD"
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
			dmenu "$([ "$WINDOWIFIED" = 0 ] && echo "-c" || echo "-wm")" -l 20 -fn Terminus-20 -c -idx $DTMFINDEX -p "DTMF Tone"
		)"
		echo "$PICKED" | grep "Return to Call Menu" && return
		DTMFINDEX=$(echo "$NUMS" | grep -bo "$PICKED" | cut -d: -f1 | xargs -IN echo 2+N | bc)
		modem_cmd_errcheck -m "$(modem_n)" -o "$CALLID" --send-dtmf="$PICKED"
	done
}

pickup() {
	acceptcall "$1"
	incallsetup "$1"
	incallmonitor "$1" &
	incallmenuloop "$1"
}

modem_n || fatalerr "Couldn't determine modem number - is modem online?"
"$@"