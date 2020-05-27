#!/usr/bin/env sh
T="$(
  find /usr/share/zoneinfo -type f | 
  sed  's#^/usr/share/zoneinfo/##g' |
  sort |
  sxmo_dmenu_with_kb.sh -p Timezone -c -l 10 -fn Terminus-20 -i
)"

st -e sh -c 'sudo setup-timezone -z '$T' && echo 1 > /tmp/sxmo_bar && echo Timezone changed ok && read'
