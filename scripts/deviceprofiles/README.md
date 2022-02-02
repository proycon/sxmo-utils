# Device profile

A device profile is a shell script that is loaded early in sxmo startup, and is
intended to be used for defining device-specific attributes that sxmo will use
at run time.

While it is technically possible to put any valid shell commands/logic in the
device profile, it is recommended to only use environment variables to keep the
script's execution time at a minimum and to keep things simple.

## Device profile variables used by sxmo
Supported variables used by sxmo are:

| Variable                | Description                                                                             | Pinephone Defaults                                                               |
|-------------------------|-----------------------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| SXMO_ROTATE_POLL_TIME   | Polling time for rotate in seconds (decimals allowed e.g. .1)                           | `export SXMO_ROTATE_POLL_TIME="1"`                                               |
| SXMO_ROTATION_GRAVITY   | Override gravity for calculating rotation                                               | `export SXMO_ROTATION_GRAVITY="500"`                                             |
| SXMO_ROTATION_THRESHOLD | Threshold for detecting rotation                                                        | `export SXMO_ROTATION_THRESHOLD="60"`                                            |
| SXMO_SPEAKER            | Audio device name for the main speaker                                                  | `export SXMO_SPEAKER="Speaker"`                                                  |
| SXMO_EARPIECE           | Audio device name for the earpiece speaker                                              | `export SXMO_EARPIECE="Earpiece"`                                                |
| SXMO_HEADPHONE          | Audio device name for the headphones                                                    | `export SXMO_HEADPHONE="Headphone"`                                              |
| SXMO_TOUCH_POINTER_ID   | ID (from xinput) for the touchscreen device                                             | `export SXMO_TOUCH_POINTER_ID="10"`                                              |
| SXMO_SYS_FILES          | String of files for sxmo_setpermissions.sh to make +rw                                  | See sxmo_setpermissions.sh.                                                      |
| SXMO_MIN_BRIGHTNESS     | Minimum brightness level                                                                | `export SXMO_MIN_BRIGHTNESS="5"`                                                 |
| SXMO_WAKEUPRTC          | RTC wakeup number in /sys/class/wakeup/wakeup<number>/ (see sxmo_screenlock.sh)         | `export SXMO_WAKEUPRTC="1"`                                                      |
| SXMO_MODEMRTC           | Modem wakeup number in /sys/class/wakeup/wakeup<number>/ (see sxmo_screenlock.sh)       | `export SXMO_MODEMRTC="10"`                                                      |
| SXMO_POWERRTC           | Power wakeup number in /sys/class/wakeup/wakeup<number>/ (see sxmo_screenlock.sh)       | `export SXMO_POWERRTC="5"`                                                       |
| SXMO_DISABLE_LEDS       | Disable leds (1 or 0)                                                                   | `export SXMO_DISABLE_LEDS="0"`                                                   |
| SXMO_LED_WHITE_TYPE     | LED device type, i.e., the part after the colon in the path: `/sys/class/leds/<color>:<type>` | `export SXMO_LED_WHITE_TYPE="status"`                                       |
| SXMO_LED_BLUE_TYPE      | LED device type, i.e., the part after the colon in the path: `/sys/class/leds/<color>:<type>` | `export SXMO_LED_BLUE_TYPE="status"`                                        |
| SXMO_LED_RED_TYPE       | LED device type, i.e., the part after the colon in the path: `/sys/class/leds/<color>:<type>` | `export SXMO_LED_RED_TYPE="status"`                                         |
| SXMO_LED_GREEN_TYPE     | LED device type, i.e., the part after the colon in the path: `/sys/class/leds/<color>:<type>` | `export SXMO_LED_GREEN_TYPE="status"`                                       |
