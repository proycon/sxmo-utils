#!/usr/bin/env sh
EDITOR=vis
LOGDIR=/home/$USER/.sxmo

err() {
	echo $1 | dmenu -fn Terminus-20 -c -l 10
	kill $$
}

modem_n() {
	mmcli -L | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
}

textcontacts() {
	# TODO: is find automatically sorted by timestamp?
	find $LOGDIR/* -type d -maxdepth 1 | awk -F'/' '{print $NF}' | tac
}

editmsg() {
	TMP="$(mktemp --suffix $1_msg)"
	echo "$2" > "$TMP"
	TEXT="$(st -e $EDITOR $TMP)"
	cat $TMP
}

sendmsg() {
	MODEM=$(modem_n)
	NUMBER="$(echo "$1" | sed 's/^[+]//' | sed 's/^1//')"
	TEXT="$2"
	TEXTSIZE="$(echo "$TEXT" | wc -c)"

	SMSNO=$(
		mmcli -m $MODEM --messaging-create-sms="text='$TEXT',number=$NUMBER" |
		grep -o [0-9]*$
	)
	mmcli -s ${SMSNO} --send || err "Couldn't send text message"
	for i in $(mmcli -m $MODEM --messaging-list-sms | grep " (sent)" | cut -f5 -d' ') ; do
	  mmcli -m $MODEM --messaging-delete-sms=$i
	done

	TIME="$(date --iso-8601=seconds)"
	mkdir -p $LOGDIR/$NUMBER
	echo -ne "Sent to $NUMBER at $TIME:\n$TEXT\n\n" >> $LOGDIR/$NUMBER/sms.txt
	echo -ne "$TIME\tsent_txt\t$NUMBER\t$TEXTSIZE chars\n" >> $LOGDIR/modemlog.tsv

	err "Sent text message ok"
}

sendtextmenu() {
	modem_n || err "Couldn't determine modem number - is modem online?"

	# Prompt for number
	NUMBER=$(
		echo -e "\nCancel\n$(textcontacts)" | 
		awk NF |
		sxmo_dmenu_with_kb.sh -p "Number" -fn "Terminus-20" -l 10 -c
	)
	echo "$NUMBER" | grep -E "^Cancel$" && exit 1
	echo "$NUMBER" | grep -E '[0-9]+' || err "That doesn't seem like a valid number"

	# Compose first version of msg
	TEXT="$(editmsg $NUMBER 'Enter text message here')"

	while true
	do
		CHARS=$(echo "$TEXT" | wc -c)
		CONFIRM=$(
			echo -e "Edit Message ($TEXT)\nSend to → $NUMBER\nCancel" |
			dmenu -c -idx 1 -p "Confirm" -fn "Terminus-20" -l 10
		)
		echo "$CONFIRM" | grep -E "^Send" && sendmsg "$NUMBER" "$TEXT" && exit 0
		echo "$CONFIRM" | grep -E "^Cancel$" && exit 1
		echo "$CONFIRM" | grep -E "^Edit Message" && TEXT="$(editmsg "$NUMBER" "$TEXT")"
	done
}

tailtextlog() {
  st -e tail -f $LOGDIR/$1/sms.txt
}

main() {
	# Display
	ENTRIES="$(echo -e "$(textcontacts)" | xargs -INUM echo NUM logfile)"
	ENTRIES="$(echo -e "Close Menu\nSend a Text\n$ENTRIES")"
	NUMBER="$(echo -e "$ENTRIES" | dmenu -p Texts -c -fn Terminus-20 -l 10)"
	echo $NUMBER | grep "Close Menu" && exit 1
	echo $NUMBER | grep "Send a Text" && sendtextmenu && exit 1
	tailtextlog "$(echo $NUMBER | sed 's/ logfile//g')"
}

main