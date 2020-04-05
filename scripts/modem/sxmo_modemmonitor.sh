#!/usr/bin/env sh
TIMEOUT=3
MODEM=$(mmcli -L | grep -o "Modem/[0-9]" | grep -o [0-9]$)

newcall() {
	sxmo_setpineled green 1

	echo "Incoming Call:"
	INCOMINGNUMBER=$(
		mmcli -m 0 --voice-list-calls -o 3 -K |
		grep call.properties.number |
		cut -d ':' -f 2
	)
	echo "Number: $INCOMINGNUMBER"
}

newtexts() {
	sxmo_setpineled green 1

	echo "New Texts:"
	for i in $(echo -e "$1") ; do
		DAT="$(mmcli -m 0 -s $i -K)"

		TEXT="$(echo "$DAT" | grep sms.content.text | sed -E 's/^sms\.content\.text\s+:\s+//')"
		NUM="$(echo "$DAT" | grep sms.content.number | sed -E 's/^sms\.content\.number\s+:\s+[+]?//')"
		TIME="$(echo "$DAT" | grep sms.properties.timestamp | sed -E 's/^sms\.properties\.timestamp\s+:\s+//')"
		TEXTSIZE="$(echo $TEXT | wc -c)"

		mkdir -p ~/.sxmo/$NUM
		echo -ne "$NUM at $TIME:\n$TEXT\n\n" >> ~/.sxmo/$NUM/sms.txt
		echo -ne "$TIME\trecv_txt\t$NUM\t$TEXTSIZE chars\n" >> ~/.sxmo/$NUM/log.tsv
		sudo mmcli -m $MODEM --messaging-delete-sms=$i
	done
}

while true
do
	sxmo_setpineled green 0
	VOICECALLID="$(
		mmcli -m 0 --voice-list-calls -a |
		grep -Eo '[0-9]+ incoming \(ringing-in\)' |
		grep -Eo '[0-9]+'
	)"

	TEXTIDS="$(
		mmcli -m 0 --messaging-list-sms |
		grep -Eo '/SMS/[0-9] \(received\)' |
		grep -Eo '[0-9]+'
	)"

	echo VIDS $VOICECALLID
	echo TIDS $TEXTIDS

	echo "$VOICECALLID" | grep . && newcall "$VOICECALLID"
	echo "$TEXTIDS" | grep . && newtexts "$TEXTIDS"
	sleep $TIMEOUT
done
