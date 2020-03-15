#!/usr/bin/env sh

P=/tmp/KEYTOG

keyoff() {
        kill -9 $(cat $P)
        pgrep -f sxmo_keyboard.sh | grep -Ev "^${$}$" | xargs kill -9
        pkill -9 svkbd-en
        pkill -9 svkbd-symbols
        rm $P
}

keyon() {
        echo $$ >> $P
        while :
        do
                svkbd-en -d
                svkbd-symbols -d
        done
}

if [ "$1" == "on" ]; then
  [ -f $P ] && keyoff
  keyon
elif [ "$1" == "off" ]; then
  [ -f $P ] && keyoff
else
  # Default toggle
  [ -f $P ] && keyoff || keyon
fi
