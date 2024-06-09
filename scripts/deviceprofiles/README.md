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

### Modem related

export SXMO_MODEM_GPIO_KEY_RI		| If the modem driver handle a gpio, sxmo have to know it to disable the events from this input source.

export SXMO_NO_MODEM		| Disable modem related features

### Screen-related
SXMO_ROTATION_POLL_TIME		| Polling time for rotate in seconds (decimals allowed e.g. .1) [default: 1]

SXMO_ROTATION_GRAVITY		| Override gravity for calculating rotation [default: 500]

SXMO_ROTATION_THRESHOLD		| Threshold for detecting rotation [default: 60]

SXMO_MIN_BRIGHTNESS		| Minimum brightness level [default: 5]

SXMO_DISABLE_LEDS		| Disable leds (1 or 0) [default: 0]

SXMO_SWAY_SCALE		| Screen scale for hidpi screens. Can be fractional [SWAY-ONLY].

SXMO_ROTATE_DIRECTION		| The direction to rotate when using the gesture [default: right]

SXMO_ROTATE_START		| Should rotate on start? (usefull when landscaped by default)

### Input-related
SXMO_TOUCHSCREEN_ID 		| ID (from xinput) for the touchscreen device [DWM-ONLY] [default: 10]

SXMO_STYLUS_ID			| ID (from xinput) for the stylus device [DWM-ONLY] [default: 10]

SXMO_LISGD_THRESHOLD		| Threshold for detecting touches [default: 125]

SXMO_LISGD_THRESHOLD_PRESSED	| Threshold for detecting long presses [default: 60]

SXMO_LISGD_INPUT_DEVICE		| Input device [default: /dev/input/by-path/first/touchscreen]

SXMO_VOLUME_BUTTON		| Volume button "Identifier" from `swaymsg -t get_inputs` command. If the volume up identifier (`$VOL_UP_ID`) is different from the volume down identifier (`$VOL_DOWN_ID`), set `$SXMO_VOLUME_BUTTON="$VOL_UP_ID $VOL_DOWN_ID"`. See the `sxmo-utils/scripts/deviceprofiles/sxmo_deviceprofile_xiaomi,beryllium.sh` file.

SXMO_POWER_BUTTON               | Power button "Identifier" from `swaymsg -t get_inputs` command.

SXMO_DISABLE_KEYBINDS		| Disable most custom Sxmo binds on volume keys if set.

SXMO_MONITOR		| Display "Output" from `swaymsg -t get_outputs`. Should be the same as the output from the `xrandr` command when running dwm.

SXMO_NO_VIRTUAL_KEYBOARD	| Disable all virtual keyboard management, and change some related gesture behavior.

### General / Misc.
SXMO_VIBRATE_DEV		| Path to vibration device (see sxmo_vibrate.c and clickclack.c) [default: /dev/input/by-path/platform-vibrator-event]
SXMO_VIBRATE_STRENGTH | Strength parameter to pass to sxmo_vibrate [default: 1]

SXMO_STATES			| The list of available state [default: "unlock lock screenoff"]

SXMO_SUSPENDABLE_STATES		| The list of suspendable states, with their timeout duration [default: "screenoff 3"]
