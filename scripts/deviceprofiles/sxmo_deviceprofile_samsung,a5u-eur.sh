#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

export SXMO_DISABLE_LEDS=1

#   0:0:MELFAS_MMS345_Touchscreen
#     BTN_TOUCH
#     ABC_X
#     ABC_Y
#     ABS_PRESSURE
#     ABS_MT_SLOT
#     ABS_MT_TOUCH_MAJOR
#     ABS_MT_POSITION_X
#     ABS_MT_POSITION_Y
#     ABS_MT_TRACKING_ID
#     ABS_MT_PRESSURE
#   0:0:samsung-a2015_Headset_Jack
#     KEY_VOLUMEDOWN
#     KEY_VOLUMEUP
#     KEY_PLAYPAUSE
#     BTN_4
#     KEY_VOICECOMMAND
#     SW_HEADPHONE_INSERT
#     SW_MICROPHONE_INSERT
#   0:0:pm8941_resin
#     KEY_VOLUMEDOWN
#   0:0:pm8941_pwrkey
#     KEY_POWER
#   0:0:tm2-touchkey
#     KEY_MENU
#     KEY_BACK
#   1:1:GPIO_Buttons
#     KEY_VOLUMEUP
#     KEY_HOMEPAGE
#   1:1:GPIO_Hall_Effect_Sensor
#     SW_LID
export SXMO_POWER_BUTTON='0:0:pm8941_pwrkey'
export SXMO_VOLUME_BUTTON='0:0:pm8941_resin 1:1:GPIO_Buttons'
# TODO: change to output display
export SXMO_MONITOR='0:0:MELFAS_MMS345_Touchscreen'

# /sys/devices/platform/soc@0/200f000.spmi/spmi-0/0-00/200f000.spmi:pmic@0:pon@800/200f000.spmi:pmic@0:pon@800:resin/wakeup/wakeup3
# /sys/devices/platform/soc@0/200f000.spmi/spmi-0/0-00/200f000.spmi:pmic@0:pon@800/200f000.spmi:pmic@0:pon@800:pwrkey/wakeup/wakeup2
# /sys/devices/platform/soc@0/200f000.spmi/spmi-0/0-00/200f000.spmi:pmic@0:rtc@6000/wakeup/wakeup0
# /sys/devices/platform/soc@0/200f000.spmi/spmi-0/0-00/200f000.spmi:pmic@0:rtc@6000/rtc/rtc0/alarmtimer.0.auto/wakeup/wakeup1
# /sys/devices/platform/soc@0/78b8000.i2c/i2c-5/5-0035/power_supply/rt5033-battery/wakeup6
# /sys/devices/virtual/wakeup/wakeup4
# /sys/devices/virtual/wakeup/wakeup5
export SXMO_WIFI_MODULE='wcn36xx'
export SXMO_SWAY_SCALE="2"
