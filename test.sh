#!/bin/bash
readonly ADMIN_PASSWORD=${ADMIN_PASSWORD:-youshouldsetapassword}

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

smbclient -L localhost -N
if [[ "$?" == "1" ]]; then
    echo "[error] Cannot login"
    exit 1
fi

smbclient //localhost/netlogon -UAdministrator%${ADMIN_PASSWORD} -c 'ls' 
if [[ "$?" == "1" ]]; then
    echo "[error] Cannot list netlogon share"
    exit 1
fi

exit 0

