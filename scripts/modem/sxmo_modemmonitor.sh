#!/usr/bin/env sh
TIMEOUT=3
LOGDIR=/home/$USER/.sxmo
ACTIVECALL="NONE"
trap "kill 0" SIGINT

err() {
	echo -e "$1" | dmenu -fn Terminus-20 -c -l 10
	kill -9 0
}

modem_n() {
  MODEMS="$(mmcli -L)"
  echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' > /dev/null || err "Couldn't find modem - is you're modem enabled?\nDisabling modem monitor"
  echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
}

newcall() {
	VID="$1"
	sxmo_vibratepine 2000 &
	sxmo_setpineled green 1

	# Delete all terminated calls
	for i in $(mmcli -m $(modem_n) --voice-list-calls | grep terminated | grep -oE Call\/[0-9]+ | cut -d'/' -f2); do
		mmcli -m $(modem_n) --voice-delete-call $i
	done

	echo "Incoming Call:"
	INCOMINGNUMBER=$(
		mmcli -m $(modem_n) --voice-list-calls -o "$VID" -K |
		grep call.properties.number |
		cut -d ':' -f 2 |
		sed 's/^[+]//' | 
		sed 's/^1//'
	)

	TIME="$(date --iso-8601=seconds)"
	mkdir -p $LOGDIR
	echo -ne "$TIME\tcall_ring\t$NUMBER\n" >> $LOGDIR/modemlog.tsv
	echo "$VID:$INCOMINGNUMBER" > /tmp/sxmo_incomingcall
	echo "Number: $INCOMINGNUMBER (VID: $VID)"

}

newtexts() {
	sxmo_setpineled green 1

	echo "New Texts:"
	for i in $(echo -e "$1") ; do
		DAT="$(mmcli -m $(modem_n) -s $i -K)"

		TEXT="$(echo "$DAT" | grep sms.content.text | sed -E 's/^sms\.content\.text\s+:\s+//')"
		NUM="$(
			echo "$DAT" | 
			grep sms.content.number | 
			sed -E 's/^sms\.content\.number\s+:\s+[+]?//' |
			sed 's/^[+]//' |
			sed 's/^1//'
		)"
		TIME="$(echo "$DAT" | grep sms.properties.timestamp | sed -E 's/^sms\.properties\.timestamp\s+:\s+//')"
		TEXTSIZE="$(echo $TEXT | wc -c)"

		mkdir -p "$LOGDIR/$NUM"
		echo -ne "Received from $NUM at $TIME:\n$TEXT\n\n" >> $LOGDIR/$NUM/sms.txt
		echo -ne "$TIME\trecv_txt\t$NUM\t$TEXTSIZE chars\n" >> $LOGDIR/modemlog.tsv
		mmcli -m $(modem_n) --messaging-delete-sms=$i

		sxmo_vibratepine 300 && sleep 0.1
		sxmo_vibratepine 300 && sleep 0.1
		sxmo_vibratepine 300
	done
}

killinprogresscall() {
	echo "Kill the in progress call"
	pkill -9 dmenu
}

inprogresscallchecker() {
	# E.g. register current call in progress as ACTIVECALL
	CURRENTCALLS="$(mmcli -m $(modem_n) --voice-list-calls)"

	# E.g. if we've previously registered an ACTIVECALL, check if it
	# was terminated by the otherside, if so kill the incall script
	# and notify user
	echo "$ACTIVECALL" | grep -E '[0-9]+' && $(
		echo "$CURRENTCALLS" | 
		grep -E "Call/${ACTIVECALL}.+terminated" && 
		killinprogresscall
	)

	# Register the active call so we can check in future loops if
	# other side hung up
	ACTIVECALL="$(
		echo "$CURRENTCALLS" | 
		grep -oE "[0-9]+ (incoming|outgoing).+active" | 
		cut -d' ' -f1
	)"

	echo "Set new Activecall:<$ACTIVECALL>"
}

while true
do
	sxmo_setpineled green 0
	VOICECALLID="$(
		mmcli -m $(modem_n) --voice-list-calls -a |
		grep -Eo '[0-9]+ incoming \(ringing-in\)' |
		grep -Eo '[0-9]+'
	)"

	TEXTIDS="$(
		mmcli -m $(modem_n) --messaging-list-sms |
		grep -Eo '/SMS/[0-9]+ \(received\)' |
		grep -Eo '[0-9]+'
	)"

	echo "Check status, VIDS: $VOICECALLID, TIDS: $TEXTIDS"

	inprogresscallchecker

	echo "$VOICECALLID" | grep . && newcall "$VOICECALLID" || rm -f /tmp/sxmo_incomingcall
	echo "$TEXTIDS" | grep . && newtexts "$TEXTIDS"
	sleep $TIMEOUT
done
