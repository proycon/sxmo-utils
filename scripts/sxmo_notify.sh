#!/usr/bin/env sh
HEIGHT=30
W=$1
FULLW=$(
  xdpyinfo |
  grep 'dimensions' |
  egrep -o "[0-9]+x[0-9]+ pixels" |
  sed "s/x.*//"
)
OFFX=$(echo $FULLW - $W - 2 | bc)

sh -c "echo $2 | dzen2 -p 2 -h $HEIGHT -x $OFFX -y 30" &
