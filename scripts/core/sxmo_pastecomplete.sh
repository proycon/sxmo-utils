#!/usr/bin/env sh
INPUT="$(cat)"

pidof svkbd-sxmo || svkbd-sxmo &

RESULT="$(
        echo "$(
                echo "Close Menu" &&
                echo "$INPUT" |\
                  grep -Eo '\S+' |\
                  tr -d '[:blank:]' |\
                  sort |\
                  uniq
        )" | dmenu -p Type -l 10 -i -c -fn Terminus-20
)"

pkill svkbd-sxmo

if [[ "$RESULT" = "Close Menu" ]]; then
  exit 0
else
  xdotool type "$RESULT"
fi
