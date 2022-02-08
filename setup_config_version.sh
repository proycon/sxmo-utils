#!/bin/sh

busybox md5sum "$1" | \
	cut -d" " -f1 | \
	xargs -I{} sed -i '2i# configversion: {}' \
	"$1"
