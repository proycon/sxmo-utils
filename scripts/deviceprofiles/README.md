# Device profile

A device profile is a shell script that is loaded early in sxmo startup, and is
intended to be used for defining device-specific attributes that sxmo will use
at run time.

While it is technically possible to put any valid shell commands/logic in the
device profile, it is recommended to only use environment variables to keep the
script's execution time at a minimum and to keep things simple.


## File name

To define a device profile, you need to first obtain the device name. This can
be found in `/proc/device-tree/compatible`.

The compatible file is a null terminated array, sxmo uses the first item as the
name of the device. For example, the poco f1 is a 3 button touch device and
`tr '\0' '\n' < /proc/device-tree/compatible` returns:

```
xiaomi,beryllium
qcom,sdm845
```

As such, `sxmo-utils/configs/default_hooks/xiaomi,beryllium`
is a symlink to `sxmo-utils/configs/default_hooks/three_button_touchscreen`.
Finally, the device profile variables (explained in the following secion) is defined in:

`sxmo-utils/scripts/deviceprofiles/sxmo_deviceprofile_xiaomi,beryllium.sh`

Further reading:
 - [Accessing the devicetree from userspace](https://www.kernel.org/doc/html/latest/admin-guide/abi-testing.html#abi-sys-firmware-devicetree)
 - [An overview of how the devicetree works on linux](https://www.kernel.org/doc/html/latest/devicetree/usage-model.html)
 - [The devicetree spec](https://github.com/devicetree-org/devicetree-specification/releases)

## Device profile variables used by sxmo
Supported variables used by sxmo are:

### Screen-related
SXMO_ROTATION_POLL_TIME		| Polling time for rotate in seconds (decimals allowed e.g. .1) [default: 1]

SXMO_ROTATION_GRAVITY		| Override gravity for calculating rotation [default: 500]

SXMO_ROTATION_THRESHOLD		| Threshold for detecting rotation [default: 60]

SXMO_MIN_BRIGHTNESS		| Minimum brightness level [default: 5]

SXMO_DISABLE_LEDS		| Disable leds (1 or 0) [default: 0]

SXMO_LED_WHITE_TYPE		| LED device type, i.e., the part after the colon in the path: `/sys/class/leds/<color>:<type>` [default: status]

SXMO_LED_BLUE_TYPE		| LED device type, i.e., the part after the colon in the path: `/sys/class/leds/<color>:<type>` [default: status]

SXMO_LED_RED_TYPE		| LED device type, i.e., the part after the colon in the path: `/sys/class/leds/<color>:<type>` [default: status]

SXMO_LED_GREEN_TYPE		| LED device type, i.e., the part after the colon in the path: `/sys/class/leds/<color>:<type>` [default: status]

### Music-related
SXMO_SPEAKER			| Audio device name for the main speaker [default: Speaker]

SXMO_EARPIECE			| Audio device name for the earpiece speaker [default: Earpiece]

SXMO_HEADPHONE			| Audio device name for the headphones [default: Headphone]

SXMO_ALSA_CONTROL_NAME	| Alsa audio control name [default: 0]

### Input-related
SXMO_TOUCHSCREEN_ID 		| ID (from xinput) for the touchscreen device [DWM-ONLY] [default: 10]

SXMO_STYLUS_ID			| ID (from xinput) for the stylus device [DWM-ONLY] [default: 10]

SXMO_LISGD_THRESHOLD		| Threshold for detecting touches [default: 125]

SXMO_LISGD_THRESHOLD_PRESSED	| Threshold for detecting long presses [default: 60]

SXMO_LISGD_INPUT_DEVICE		| Input device [default: /dev/input/touchscreen]

SXMO_VOLUME_BUTTON		| Volume button "Identifier" from `swaymsg -t get_inputs` command. If the volume up identifier (`$VOL_UP_ID`) is different from the volume down identifier (`$VOL_DOWN_ID`), set `$SXMO_VOLUME_BUTTON="$VOL_UP_ID $VOL_DOWN_ID"`. See the `sxmo-utils/scripts/deviceprofiles/sxmo_deviceprofile_berylliumqcom.sh` file.

### General / Misc.
SXMO_WIFI_MODULE		| The wifi kernel module used when switching scan intervals

SXMO_SYS_FILES			| String of files for sxmo_setpermissions.sh to make +rw [see sxmo_setpermissions.sh.]

SXMO_WAKEUPRTC			| RTC wakeup number in /sys/class/wakeup/wakeup<number>/ (see sxmo_suspend.sh) [default: 1]

SXMO_MODEMRTC			| Modem wakeup number in /sys/class/wakeup/wakeup<number>/ (see sxmo_suspend.sh) [default: 10]

SXMO_POWERRTC			| Power wakeup number in /sys/class/wakeup/wakeup<number>/ (see sxmo_suspend.sh) [default: 5]

SXMO_COVERRTC			| Open cover wakeup number in /sys/class/wakeup/wakeup<number>/ (see sxmo_suspend.sh) [default: 9999]
