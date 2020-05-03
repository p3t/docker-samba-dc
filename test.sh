#!/bin/bash

# Quick test for a running samba container

set -e

if [[ ! -f /etc/samba/smb.conf ]]; then
    echo "[ERROR] /etc/samba/smb.conf not found"
    exit 1
fi

readonly realm=`echo "\n" | samba-tool testparm | grep "realm"`
if [[ "${realm}" == "" ]]; then
    echo "[Error] No realm found!"
    exit 1
fi
echo "[OK] realm found: ${realm}"

exit 0

