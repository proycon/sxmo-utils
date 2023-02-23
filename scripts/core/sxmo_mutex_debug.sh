#! /bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

watch 'cat /sys/power/wake_lock | tr " " "\n"'
