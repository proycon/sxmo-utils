# Device profile

A device profile is a shell script that is loaded early in sxmo startup, and is
intended to be used for defining device-specific attributes that sxmo will use
at run time.

While it is technically possible to put any valid shell commands/logic in the
device profile, it is recommended to only use environment variables to keep the
script's execution time at a minimum and to keep things simple.

## Device profile variables used by sxmo
Supported variables used by sxmo are:

| Variable           | Description                                                                                  | Example                                                                          |
|--------------------|----------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| BACKLIGHT          | Path to the display backlight in sysfs                                                       | `export BACKLIGHT="/sys/devices/platform/backlight-dsi/backlight/backlight-dsi"` |
| FLASH_LED          | Path to the camera flash LED (also used for a flashlight) in sysfs                           | `export FLASH_LED="/sys/class/leds/white:torch"`                                 |
| LED_BLUE_TYPE      | LED device type, i.e. the part after the colon in the path: `/sys/class/leds/<color>:<type>` | `export LED_BLUE_TYPE="status"`                                                  |
| LED_GREEN_TYPE     | LED device type, i.e. the part after the colon in the path: `/sys/class/leds/<color>:<type>` | `export LED_GREEN_TYPE="status"`                                                 |
| LED_RED_TYPE       | LED device type, i.e. the part after the colon in the path: `/sys/class/leds/<color>:<type>` | `export LED_RED_TYPE="status"`                                                   |
| LED_WHITE_TYPE     | LED device type, i.e. the part after the colon in the path: `/sys/class/leds/<color>:<type>` | `export LED_WHITE_TYPE="kbd_backlight"`                                          |
| ROTATION_GRAVITY   | Override gravity for calculating rotation                                                    | `export ROTATION_GRAVITY="500"`                                                  |
| ROTATION_THRESHOLD | Threshold for detecting rotation                                                             | `export ROTATION_THRESHOLD="60"`                                                 |
| SPEAKER            | Audio device name for the main speaker                                                       | `export SPEAKER="Speaker"`                                                       |
| EARPIECE           | Audio device name for the earpiece speaker                                                   | `export EARPIECE="Earpiece"`                                                     |
| HEADPHONE          | Audio device name for the headphones                                                         | `export HEADPHONE="Headphone"`                                                   |
| SXMO_TOUCH_POINTER_ID   | ID (from xinput) for the touchscreen device                                                  | `export SXMO_TOUCH_POINTER_ID="10"`                                         |
