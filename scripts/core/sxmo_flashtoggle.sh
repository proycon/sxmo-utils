#!/bin/sh

[ -z "$FLASH_LED" ] && FLASH_LED=/sys/class/leds/white:flash

sxmo_setled.sh white "$(
	grep -qE '^0$' "$FLASH_LED"/brightness &&
	echo 255 || echo 0
)"

