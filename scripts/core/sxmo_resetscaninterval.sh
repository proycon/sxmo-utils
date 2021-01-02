#!/bin/sh

# this script resets the wireless scan interval (value is in ms)
# it is invoked with a delay after waking from sleep
# to prevent the scan interval from being too quick, and thus
# too battery consuming, whilst no networks are found

# the kernel parameter must be writable for the user
# or this script must have the setsuid bit set!

echo 16000 > /sys/module/8723cs/parameters/rtw_scan_interval_thr
