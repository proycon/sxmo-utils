#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors
# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

trap "read -r" EXIT

update_apk() {
	echo "Updating all packages from repositories"
	doas apk update

	echo "Upgrading all packages"
	doas apk upgrade -v

	echo "Upgrade complete - reboot for all changes to take effect"
}

update_pacman() {
	echo "Upgrading all packages"
	doas pacman -Syu

	echo "Upgrade complete - reboot for all changes to take effect"
}

update_nixos() {
	echo "Upgrading all packages"
	# nohup needed because nixos-rebuild might restart the display manager
	# (and thus the terminal we're running in) before the update is complete
	doas nohup nixos-rebuild switch --upgrade > /tmp/sxmo-last-upgrade.log &
	coreutils --coreutils-prog=tail -f /tmp/sxmo-last-upgrade.log --pid=$!

	echo "Upgrade complete - reboot for all changes to take effect"
}

echo "upgrading" | doas tee -a /sys/power/wake_lock > /dev/null

case "$OS" in
	alpine|postmarketos) update_apk;;
	arch|archarm) update_pacman;;
	nixos) update_nixos;;
esac

echo "upgrading" | doas tee -a /sys/power/wake_unlock > /dev/null
