#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

if [ -z "$SXMO_NO_MODEM" ]; then
	MMCLI="$(mmcli -m any -J 2>/dev/null)"
	if [ -z "$MMCLI" ]; then
		sxmo_notify_user.sh "Modem crashed! 30s recovery."
		sxmo_wakelock.sh lock sxmo_modem_crashed 30s
	fi
fi

# Add here whatever you want to do
