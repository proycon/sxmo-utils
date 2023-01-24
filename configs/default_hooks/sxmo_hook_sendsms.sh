#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script is executed after you send a text
#You can use it to play a notification sound or forward the sms elsewhere

#The following parameters are provided:
# $1 = Contact Name or Number (if number not in contacts)
# $2 = Text
# mms / group chats will also include these parameters:
# $3 = MMS payload ID
# $4 = Group Contact Name or Number (if number not included in contacts)

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

mpv --quiet --no-video "$(xdg_data_path sxmo/notify.ogg)" >> /dev/null 2>&1
