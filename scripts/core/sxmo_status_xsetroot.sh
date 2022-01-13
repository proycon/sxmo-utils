#!/bin/sh

sxmo_status.sh watch | stdbuf -o0 tr '\n' '\0' | xargs -0 -n1 xsetroot -name
