#!/usr/bin/env sh

err() {
	echo $1 | dmenu -fn Terminus-20 -c -l 10
	exit 1
}

modem_n() {
  mmcli -L | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
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
  NUMS=$(ls -1 ~/.sxmo || "")
	NUMBER="$(
		echo -e "$NUMS\nTest Number 804-222-1111" | 
		dmenu -l 10 -p Number -c -fn Terminus-20 |
		awk -F' ' '{print $NF}' |
		tr -d -
	)"
	echo "Attempting to dial: $NUMBER" >&2
	VID="$(
		sudo mmcli -m $(modem_n) --voice-create-call "number=$NUMBER" | grep -Eo Call/[0-9]+ | grep -oE [0-9]+
	)"
	echo "Starting call with VID: $VID" >&2
	startcall $VID >&@
	echo $VID
}

startcall() {
  VID="$1"
  sudo mmcli --voice-status -o $VID
	sudo mmcli -m $(modem_n) -o $VID --start | grep "successfully started" || err "Couldn't start call!"
}

acceptcall() {
  VID="$1"
  echo "Attempting to pickup VID $VID"
  sudo mmcli --voice-status -o $VID
	sudo mmcli -m $(modem_n) -o $VID --accept | grep "successfully" || err "Couldn't accept call!"
}

hangup() {
  VID=$1
  sudo mmcli -m $(modem_n) -o $VID --hangup | grep "successfully hung up" || err "Failed to hangup the call?"
  exit 1
}

incallmenu() {
  DMENUIDX=0
  VID="$1"
  NUMBER=$(mmcli -m $(modem_n) -o $VID -K | grep call.properties.number | cut -d ':' -f2 | tr -d  ' ')
  # E.g. Run once w/o -2, and then run once with -2
  FLAGS="-e -m"
  sxmo_megiaudioroute $FLAGS
  FLAGS="$FLAGS -2"
  sxmo_megiaudioroute $FLAGS

  while true
  do
    echo -- "$FLAGS" | grep -- "-m" && TMUTE="Mute" || TMUTE="Unmute"
    echo -- "$FLAGS" | grep -- "-z" && TECHO="Echomic Off" || TECHO="Echomic On"
    echo -- "$FLAGS" | grep -- "-e" && TEARPIECE="Earpiece Off" || TEARPIECE="Earpiece On"
    echo -- "$FLAGS" | grep -- "-h" && TLINEJACK="Linejack Off" || TLINEJACK="Linejack On"
    echo -- "$FLAGS" | grep -- "-s" && TSPEAKER="Speakerphone Off" || TSPEAKER="Speakerphone On"

    CHOICES="$(echo -ne '
        Volume ↑ ^ sxmo_vol.sh up
        Volume ↓ ^ sxmo_vol.sh down
        TMUTE ^ FLAGS="$(toggleflag "-m" "$FLAGS")"
        TECHO ^ FLAGS="$(toggleflag "-z" "$FLAGS")"
        TEARPIECE ^ FLAGS="$(toggleflag "-e" "$FLAGS")"
        TLINEJACK ^ FLAGS="$(toggleflag "-h" "$FLAGS")"
        TSPEAKER ^ FLAGS="$(toggleflag "-s" "$FLAGS")"
        DTMF Tones ^ dtmfmenu $VID
        Hangup ^ hangup $VID
        Lock Screen ^ sxmo_screenlock
      ' | sed "s/TMUTE/$TMUTE/;s/TECHO/$TECHO/;s/TEARPIECE/$TEARPIECE/;s/TLINEJACK/$TLINEJACK/;s/TSPEAKER/$TSPEAKER/"
    )"

    PICKED=$(
      echo "$CHOICES" | 
      xargs -0 echo | 
      cut -d'^' -f1 | 
      sed '/^[[:space:]]*$/d' |
      awk '{$1=$1};1' |
      dmenu -idx $DMENUIDX -l 14 -c -fn "Terminus-30" -p "$NUMBER"
    )
    CMD=$(echo "$CHOICES" | grep "$PICKED" | cut -d '^' -f2)
    DMENUIDX=$(echo $(echo "$CHOICES" | grep -n "$PICKED" | cut -d ':' -f1) - 1 | bc)
    eval $CMD
  done
}

dtmfmenu() {
  VID=$1
  DMENUIDX=0
  NUMS="0123456789*#ABCD"

  while true
  do
    PICKED="$(
      echo "$NUMS" | grep -o . | sed '1 iReturn to Call Menu' |
      dmenu -l 20 -fn Terminus-20 -c -idx $DMENUIDX -p "DTMF Tone"
    )"
    DMENUIDX=$(echo "$NUMS" | grep -bo "$PICKED" | cut -d: -f1 | xargs -IN echo 2+N | bc)

    echo "$PICKED" | grep "Return to Call Menu" && break
    sudo mmcli -m $(modem_n) -o $VID --send-dtmf="$PICKED"
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
