#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

export WLR_RENDERER=pixman
export SXMO_DISABLE_LEDS=1 #disable for now although N900 has leds, but paths are different
export SXMO_POWER_BUTTON="0:0:twl_pwrbutton"
export SXMO_SWAY_SCALE="1.5"
#on N900 these two are swaped
export SXMO_BEMENU_LANDSCAPE_LINES="10"
export SXMO_BEMENU_PORTRAIT_LINES="8"
export SXMO_ROTATE_DIRECTION="left"
export SXMO_KEYBOARD_SLIDER_EVENT_DEVICE="/dev/input/by-path/platform-gpio_keys-event"
export SXMO_KEYBOARD_SLIDER_CLOSE_EVENT="*code 10 (SW_KEYPAD_SLIDE), value 0*"
export SXMO_KEYBOARD_SLIDER_OPEN_EVENT="*code 10 (SW_KEYPAD_SLIDE), value 1*"
