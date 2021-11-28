#!/bin/bash

readonly DOMAIN=${DOMAIN:-test.domain.local}
readonly ADMIN_PASSWORD=${ADMIN_PASSWORD:-8minPass}
readonly DNS_FORWARD=${DNS_FORWARD:-'1.1.1.3 1.0.0.3'}

docker run --rm \
    --privileged=true \
    --mount source=samba,target=/samba \
    -eDOMAIN=${DOMAIN} \
    -eNO_COMPLEXITY=true \
    -eADMIN_PASSWORD=${ADMIN_PASSWORD} \
    -eDNS_FORWARD=${DNS_FORWARD} \
    p3tr/samba-dc setup