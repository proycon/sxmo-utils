#!/usr/bin/env sh
pgrep -f sxmo_statusbar.sh | grep -v $$ | xargs kill -9

sleep 1
UPDATEFILE=/tmp/sxmo_bar
touch $UPDATEFILE

while :
do
        # M symbol if modem monitoring is on & modem present
        MODEMMON=""
        pgrep -f sxmo_modemmonitor.sh && MODEMMON="M "

        # Battery pct
        PCT=$(cat /sys/class/power_supply/*-battery/capacity)
        BATSTATUS=$(
                cat /sys/class/power_supply/*-battery/status |
                cut -c1
        )

        # Volume
        AUDIODEV="$(sxmo_audiocurrentdevice.sh)"
        [[ $AUDIODEV == "None" ]] && VOL="" || VOL=$(echo "$AUDIODEV" | cut -c1 | tr L S)"$(
                amixer sget "$AUDIODEV" |
                grep -oE '([0-9]+)%' |
                tr -d ' %' |
                awk '{ s += $1; c++ } END { print s/c }'  |
                xargs printf %.0f
        )"

        # Time
        TIME=$(date +%R)

        BAR=" ${MODEMMON}${VOL} ${BATSTATUS}${PCT}% ${TIME}"
        xsetroot -name "$BAR"

        inotifywait -e MODIFY $UPDATEFILE & sleep 30 & wait -n
        pgrep -P $$ | xargs kill -9
done
