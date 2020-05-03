#!/usr/bin/env sh
UPDATEFILE=/tmp/sxmo_bar
touch $UPDATEFILE

while :
do
        PCT=$(cat /sys/class/power_supply/*-battery/capacity)
        BATSTATUS=$(
                cat /sys/class/power_supply/*-battery/status |
                cut -c1
        )

        VOL=$(
                echo "$(amixer sget Headphone || amixer sget Speaker)" |
                grep -oE '([0-9]+)%' |
                tr -d ' %' |
                awk '{ s += $1; c++ } END { print s/c }'  |
                xargs printf %.0f
        )

        TIME=$(date +%R)

        BAR=" V${VOL} ${BATSTATUS}${PCT}% ${TIME}"
        xsetroot -name "$BAR"

        inotifywait -e MODIFY $UPDATEFILE & sleep 5 & wait -n
        pgrep -P $$ | xargs kill -9
done