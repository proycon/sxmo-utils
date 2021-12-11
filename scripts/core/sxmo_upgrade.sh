#!/bin/sh
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

case "$OS" in
	alpine|postmarketos) update_apk;;
	arch|archarm) update_pacman;;
esac
