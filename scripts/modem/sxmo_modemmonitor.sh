#!/usr/bin/env sh
TIMEOUT=3

modem_n() {
  mmcli -L | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
}

newcall() {
	VID="$1"
	sxmo_setpineled green 1

	for i in $(sudo mmcli -m $(modem_n) --voice-list-calls | grep terminated | grep -oE Call\/[0-9]+ | cut -d'/' -f2); do
		sudo mmcli -m $(modem_n) --voice-delete-call $i
	done

	echo "Incoming Call:"
	INCOMINGNUMBER=$(
		mmcli -m $(modem_n) --voice-list-calls -o "$VID" -K |
		grep call.properties.number |
		cut -d ':' -f 2
	)
	echo "$VID:$INCOMINGNUMBER" > /tmp/sxmo_incomingcall
	echo "Number: $INCOMINGNUMBER (VID: $VID)"
}

newtexts() {
	sxmo_setpineled green 1

	echo "New Texts:"
	for i in $(echo -e "$1") ; do
		DAT="$(mmcli -m $(modem_n) -s $i -K)"

		TEXT="$(echo "$DAT" | grep sms.content.text | sed -E 's/^sms\.content\.text\s+:\s+//')"
		NUM="$(echo "$DAT" | grep sms.content.number | sed -E 's/^sms\.content\.number\s+:\s+[+]?//')"
		TIME="$(echo "$DAT" | grep sms.properties.timestamp | sed -E 's/^sms\.properties\.timestamp\s+:\s+//')"
		TEXTSIZE="$(echo $TEXT | wc -c)"

		mkdir -p ~/.sxmo/$NUM
		echo -ne "$NUM at $TIME:\n$TEXT\n\n" >> ~/.sxmo/$NUM/sms.txt
		echo -ne "$TIME\trecv_txt\t$NUM\t$TEXTSIZE chars\n" >> ~/.sxmo/$NUM/log.tsv
		sudo mmcli -m $(modem_n) --messaging-delete-sms=$i
	done
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

	echo VIDS $VOICECALLID
	echo TIDS $TEXTIDS

	echo "$VOICECALLID" | grep . && newcall "$VOICECALLID" || rm /tmp/sxmo_incomingcall
	echo "$TEXTIDS" | grep . && newtexts "$TEXTIDS"
	sleep $TIMEOUT
done
