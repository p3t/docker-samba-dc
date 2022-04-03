#!/bin/bash
set -x

readonly DOMAIN=${DOMAIN:-test.domain.local}
readonly ADMIN_PASSWORD=${ADMIN_PASSWORD:-8minPass}
readonly DNS_FORWARD=${DNS_FORWARD:-'1.1.1.3 1.0.0.3'}

setupDC () {
    docker run --rm \
        --privileged=true \
        --mount source=samba,destination=/samba \
        --mount source=samba-data,destination=/var/lib/samba \
        -eDOMAIN=${DOMAIN} \
        -eNO_COMPLEXITY=true \
        -eADMIN_PASSWORD=${ADMIN_PASSWORD} \
        -eDNS_FORWARD="${DNS_FORWARD}" \
        p3tr/samba-dc setup
}

runDC () {
#        --mount source=/etc/localtime,destination=/etc/localtime,readonly \
    docker run -d\
        --mount source=samba,target=/samba \
        --mount source=samba-data,destination=/var/lib/samba \
        p3tr/samba-dc run
}

# Join a secondary DC
joinDC () {
    docker run -d\
        --mount source=samba2,target=/samba \
        --mount source=samba2-data,destination=/var/lib/samba \
        -eADMIN_PASSWORD=${ADMIN_PASSWORD} \        
        p3tr/samba-dc join
}


case "$1" in
	setup)
		setupDC
		;;
	run)
		runDC
		;;
	join)
		joinDC
		;;
esac