#!/bin/sh

comment="#"
case "$(head -n1 "$1")" in
	!*)
		comment="!"
		;;
	--*)
		comment="--"
		;;
esac

busybox md5sum "$1" | \
	cut -d" " -f1 | \
	xargs -I{} sed -i "2i$comment configversion: {}" \
	"$1"
