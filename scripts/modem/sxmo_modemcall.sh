#!/usr/bin/env sh
LOGDIR="$XDG_CONFIG_HOME"/sxmo/modem
trap "kill 0" INT

err() {
	printf %b "$1" | dmenu -fn Terminus-20 -c -l 10
	alsactl --file /usr/share/sxmo/default_alsa_sound.conf restore
	kill -9 0
}

modem_n() {
	MODEMS="$(mmcli -L)"
	echo "$MODEMS" | grep -qoE 'Modem\/([0-9]+)' || err "Couldn't find modem - is your modem enabled?"
	echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
}

contacts() {
	RES="$(cut -f3 "$LOGDIR/modemlog.tsv" | sort | uniq | awk NF)"
	echo "$RES"
	printf %b "$RES" | grep -q 8042221111 || echo "Test Number 8042221111"
}

modem_cmd_errcheck() {
	ARGS="$@"
	RES="$(mmcli $ARGS 2>&1)"
	[ $? -eq 0 ] || err "Problem executing mmcli command!\n$RES"
	echo "$RES"
}

vid_to_number() {
  mmcli -m "$(modem_n)" -o "$1" -K | grep call.properties.number | cut -d ':' -f2 | tr -d  ' ' | sed 's/^[+]//' | sed 's/^1//'
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
	FLAGS="$@"

	echo -- "$FLAGS" | grep -- "$TOGGLEFLAG" >&2 && 
		NEWFLAGS="$(echo -- "$FLAGS" | sed "s/$TOGGLEFLAG//g")" ||
		NEWFLAGS="$(echo -- "$FLAGS $TOGGLEFLAG")"

	NEWFLAGS="$(echo -- "$NEWFLAGS" | sed "s/--//g; s/  / /g")"

	sxmo_megiaudioroute $NEWFLAGS
	echo -- "$NEWFLAGS"
}

toggleflagset() {
	FLAGS="$(toggleflag "$1" "$FLAGS")"
}


dialmenu() {
  CONTACTS="$(contacts)"
	NUMBER="$(
		printf %b "Close Menu\n$CONTACTS" | 
		grep . |
		sxmo_dmenu_with_kb.sh -l 10 -p Number -c -fn Terminus-20
	)"
	echo "$NUMBER" | grep "Close Menu" && kill 0

	NUMBER="$(echo "$NUMBER" | awk -F' ' '{print $NF}' | tr -d -)"
	echo "$NUMBER" | grep -qE '^[0-9]+$' || err "$NUMBER is not a number"

	echo "Attempting to dial: $NUMBER" >&2
	VID="$(
		mmcli -m "$(modem_n)" --voice-create-call "number=$NUMBER" | 
		grep -Eo "Call/[0-9]+" | 
		grep -oE "[0-9]+"
	)"
	echo "Starting call with VID: $VID" >&2
	startcall "$VID" >&@
	echo "$VID"
}

startcall() {
  VID="$1"
  #modem_cmd_errcheck --voice-status -o $VID
	modem_cmd_errcheck -m "$(modem_n)" -o "$VID" --start
	log_event "call_start" "$VID"
}

acceptcall() {
	VID="$1"
	echo "Attempting to pickup VID $VID"
	#mmcli --voice-status -o $VID
	modem_cmd_errcheck -m "$(modem_n)" -o "$VID" --accept
	log_event "call_pickup" "$VID"
}

hangup() {
	VID="$1"
	modem_cmd_errcheck -m "$(modem_n)" -o "$VID" --hangup
	log_event "call_hangup" "$VID"
	err "Call hungup ok"
	exit 1
}

incallmenu() {
  DMENUIDX=0
  VID="$1"
  NUMBER="$(vid_to_number "$VID")"

  # E.g. There's some bug with the modem that' requires us to toggle the
  # DAI a few times before starting the call for it to kick in
  FLAGS=" "
  toggleflagset "-e"
  toggleflagset "-m"
  toggleflagset "-2"
  toggleflagset "-2"
  toggleflagset "-2"

  while true
  do
    CHOICES="
      Volume ↑    ^ sxmo_vol.sh up
      Volume ↓    ^ sxmo_vol.sh down
      Mic $(echo -- $FLAGS | grep -q -- -m && echo ✓)          ^ toggleflagset -m
      Linemic $(echo -- $FLAGS | grep -q -- -l && echo ✓)      ^ toggleflagset -l
      Echomic $(echo -- $FLAGS | grep -q -- -z && echo ✓)      ^ toggleflagset -z
      Earpiece $(echo -- $FLAGS | grep -q -- -e && echo ✓)     ^ toggleflagset -e
      Linejack $(echo -- $FLAGS | grep -q -- -h && echo ✓)     ^ toggleflagset -h
      Speakerphone $(echo -- $FLAGS | grep -q -- -s && echo ✓) ^ toggleflagset -s
      DTMF Tones  ^ dtmfmenu $VID
      Hangup      ^ hangup $VID
      Lock Screen ^ sh -c 'pkill -9 lisgd; sxmo_screenlock; lisgd &'
    "

    PICKED=""
    PICKED=$(
      echo "$CHOICES" | 
      xargs -0 echo | 
      cut -d'^' -f1 | 
      sed '/^[[:space:]]*$/d' |
      awk '{$1=$1};1' |
      dmenu -idx $DMENUIDX -l 14 -c -fn "Terminus-30" -p "$NUMBER"
    )

    # E.g. in modem watcher script we just kill dmenu if the other side hangsup
    echo "$PICKED" | grep -Ev "." && err "$NUMBER hung up the call"

    CMD=$(echo "$CHOICES" | grep "$PICKED" | cut -d '^' -f2)
    DMENUIDX=$(echo $(echo "$CHOICES" | grep -n "$PICKED" | cut -d ':' -f1) - 1 | bc)
    eval $CMD
  done
}

dtmfmenu() {
  VID="$1"
  DTMFINDEX=0
  NUMS="0123456789*#ABCD"

  while true
  do
    PICKED="$(
      echo "$NUMS" | grep -o . | sed '1 iReturn to Call Menu' |
      dmenu -l 20 -fn Terminus-20 -c -idx $DTMFINDEX -p "DTMF Tone"
    )"
    echo "$PICKED" | grep "Return to Call Menu" && return
    DTMFINDEX=$(echo "$NUMS" | grep -bo "$PICKED" | cut -d: -f1 | xargs -IN echo 2+N | bc)
    modem_cmd_errcheck -m "$(modem_n)" -o "$VID" --send-dtmf="$PICKED"
  done
}

dial() {
	VID="$(dialmenu)"
	incallmenu "$VID"
}

pickup() {
	acceptcall $1
	incallmenu $1
}

modem_n || err "Couldn't determine modem number - is modem online?"
$@
