#!/usr/bin/env sh
echo "Updating all packages from repositories"
sudo apk update

echo "Upgrading all packages"
sudo apk upgrade

echo "Upgrade complete - reboot for all change to take effect"
read
