#!/usr/bin/env sh
INPUT="$(cat)"

pidof svkbd-sxmo || svkbd-sxmo &

capfirstchar() {
  awk -F  -vOFS= {$1=toupper($1);print $0}
}

RESULT="$(
        echo "$(
                echo "Close Menu" &&
                echo "$INPUT" |\
                  grep -Eo '\S+' |\
                  tr -d '[:blank:]' |\
                  sort |\
                  uniq
        )" | dmenu -p $(echo $1 | capfirstchar) -l 10 -i -c -fn Terminus-20
)"

pkill svkbd-sxmo

copy() {
  if [[ "$RESULT" = "Close Menu" ]]; then
    exit 0
  else
    echo "$RESULT" | xsel -i
  fi
}

type() {
  if [[ "$RESULT" = "Close Menu" ]]; then
    exit 0
  else
    xdotool type "$RESULT"
  fi
}

$@
