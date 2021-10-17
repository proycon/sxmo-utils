#!/usr/bin/env sh
# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

echo "Updating all packages from repositories"
doas apk update

echo "Upgrading all packages"
doas apk upgrade

echo "Upgrade complete - reboot for all changes to take effect"
read -r
