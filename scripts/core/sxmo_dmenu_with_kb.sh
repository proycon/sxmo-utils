#!/usr/bin/env sh

wasopen="$(sxmo_keyboard.sh isopen && echo "yes")"

sxmo_keyboard.sh open
OUTPUT="$(cat | dmenu "$@")"
[ -z "$wasopen" ] && sxmo_keyboard.sh close
echo "$OUTPUT"
