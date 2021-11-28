#!/usr/bin/env sh
# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

trap "read -r" EXIT

update_apk() {
	echo "Updating all packages from repositories"
	doas apk update

	echo "Upgrading all packages"
	doas apk upgrade

	echo "Upgrade complete - reboot for all changes to take effect"
}

update_pacman() {
	echo "Upgrading all packages"
	doas pacman -Syu

	echo "Upgrade complete - reboot for all changes to take effect"
}

case "$OS" in
	"Alpine Linux"|postmarketOS) upgrade_apk;;
	"Arch Linux ARM"|alarm) upgrade_pacman;;
esac
