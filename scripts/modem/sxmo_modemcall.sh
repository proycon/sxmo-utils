#!/usr/bin/env sh
PID=$$
LOGDIR=/home/$USER/.sxmo
trap "kill 0" SIGINT

err() {
	echo -e "$1" | dmenu -fn Terminus-20 -c -l 10
	alsactl --file /usr/share/sxmo/default_alsa_sound.conf restore
	kill -9 0
}

modem_n() {
  MODEMS="$(mmcli -L)"
  echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' > /dev/null || err "Couldn't find modem - is your modem enabled?"
  echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
}

contacts() {
	RES="$(cat $LOGDIR/modemlog.tsv | cut -f3 | sort | uniq | awk NF)"
	echo "$RES"
	echo -e "$RES" | grep 8042221111 > /dev/null || echo "Test Number 8042221111"
}

modem_cmd_errcheck() {
	ARGS="$@"
	RES="$(mmcli $ARGS 2>&1)"
	[[ $? -eq 0 ]] || err "Problem executing mmcli command!\n$RES"
	echo $RES
}

vid_to_number() {
  mmcli -m $(modem_n) -o $1 -K | grep call.properties.number | cut -d ':' -f2 | tr -d  ' ' | sed 's/^[+]//' | sed 's/^1//'
}

log_event() {
	EVT_HANDLE="$1"
	EVT_VID="$2"
	NUM="$(vid_to_number $EVT_VID)"
	TIME="$(date --iso-8601=seconds)"
	mkdir -p $LOGDIR
	echo -ne "$TIME\t$EVT_HANDLE\t$NUM\n" >> $LOGDIR/modemlog.tsv
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
  echo -- $NEWFLAGS
}

dialmenu() {
  CONTACTS="$(contacts)"
	NUMBER="$(
		echo -e "Close Menu\n$CONTACTS" | 
		grep . |
		sxmo_dmenu_with_kb.sh -l 10 -p Number -c -fn Terminus-20
	)"
	echo "$NUMBER" | grep "Close Menu" && kill 0

	NUMBER="$(echo $NUMBER | awk -F' ' '{print $NF}' | tr -d -)"
	echo "$NUMBER" | grep -E '^[0-9]+$'>  /dev/null || err "$NUMBER is not a number"

	echo "Attempting to dial: $NUMBER" >&2
	VID="$(
		mmcli -m $(modem_n) --voice-create-call "number=$NUMBER" | grep -Eo Call/[0-9]+ | grep -oE [0-9]+
	)"
	echo "Starting call with VID: $VID" >&2
	startcall $VID >&@
	echo $VID
}

startcall() {
  VID="$1"
  #modem_cmd_errcheck --voice-status -o $VID
	modem_cmd_errcheck -m $(modem_n) -o $VID --start
	log_event "call_start" "$VID"
}

acceptcall() {
  VID="$1"
  echo "Attempting to pickup VID $VID"
  #mmcli --voice-status -o $VID
	modem_cmd_errcheck -m $(modem_n) -o $VID --accept
	log_event "call_pickup" $VID
}

hangup() {
  VID=$1
  modem_cmd_errcheck -m $(modem_n) -o $VID --hangup
	log_event "call_hangup" $VID
	err "Call hungup ok"
  exit 1
}

incallmenu() {
  DMENUIDX=0
  VID="$1"
  NUMBER="$(vid_to_number $VID)"

  # E.g. There's some bug with the modem that' requires us to toggle the
  # DAI a few times before starting the call for it to kick in
  FLAGS=" "
  FLAGS="$(toggleflag "-e" "$FLAGS")"
  FLAGS="$(toggleflag "-m" "$FLAGS")"
  FLAGS="$(toggleflag "-2" "$FLAGS")"
  FLAGS="$(toggleflag "-2" "$FLAGS")"
  FLAGS="$(toggleflag "-2" "$FLAGS")"

  while true
  do
    echo -- "$FLAGS" | grep -- "-m" && TMUTE="Mute" || TMUTE="Unmute"
    echo -- "$FLAGS" | grep -- "-z" && TECHO="Echomic Off" || TECHO="Echomic On"
    echo -- "$FLAGS" | grep -- "-e" && TEARPIECE="Earpiece Off" || TEARPIECE="Earpiece On"
    echo -- "$FLAGS" | grep -- "-h" && TLINEJACK="Linejack Off" || TLINEJACK="Linejack On"
    echo -- "$FLAGS" | grep -- "-s" && TSPEAKER="Speakerphone Off" || TSPEAKER="Speakerphone On"

    CHOICES="$(echo -ne '
        Volume ↑    ^ sxmo_vol.sh up
        Volume ↓    ^ sxmo_vol.sh down
        TMUTE       ^ FLAGS="$(toggleflag "-m" "$FLAGS")"
        TECHO       ^ FLAGS="$(toggleflag "-z" "$FLAGS")"
        TEARPIECE   ^ FLAGS="$(toggleflag "-e" "$FLAGS")"
        TLINEJACK   ^ FLAGS="$(toggleflag "-h" "$FLAGS")"
        TSPEAKER    ^ FLAGS="$(toggleflag "-s" "$FLAGS")"
        DTMF Tones  ^ dtmfmenu $VID
        Hangup      ^ hangup $VID
        Lock Screen ^ sh -c "pkill -9 lisgd; sxmo_screenlock; lisgd &"
      ' | sed "s/TMUTE/$TMUTE/;s/TECHO/$TECHO/;s/TEARPIECE/$TEARPIECE/;s/TLINEJACK/$TLINEJACK/;s/TSPEAKER/$TSPEAKER/"
    )"

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
  VID=$1
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
    modem_cmd_errcheck -m $(modem_n) -o $VID --send-dtmf="$PICKED"
  done
}

dial() {
  VID="$(dialmenu)"
  incallmenu $VID
}

pickup() {
	acceptcall $1
	incallmenu $1
}

modem_n || err "Couldn't determine modem number - is modem online?"
$@
