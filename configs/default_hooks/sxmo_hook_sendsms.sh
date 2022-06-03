#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script is executed after you send a text
#You can use it to play a notification sound or forward the sms elsewhere

#The following parameters are provided:
#$1 = Number
#$2 = Text
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

mpv --quiet --no-video "$(xdg_data_path sxmo/notify.ogg)"
