#!/bin/sh

[ -z "$FLASH_LED" ] && FLASH_LED=/sys/class/leds/white:flash

if sxmo_led.sh get white | grep -vq ^100$; then
	sxmo_led.sh set white 100
else
	sxmo_led.sh set white 0
fi
