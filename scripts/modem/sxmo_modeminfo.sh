#!/usr/bin/env sh
modem_n() {
  mmcli -L | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
}

st -e sh -c "mmcli -m $(modem_n) && read"
