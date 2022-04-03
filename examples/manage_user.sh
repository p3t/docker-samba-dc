#!/bin/bash
set -x

readonly DOMAIN=${DOMAIN:-"test.domain.local"}
readonly USER_NAME=${USER_NAME:-"test"}
readonly USER_MAIL=${USER_MAIL:-"$USER_NAME@$DOMAIN"}
readonly USER_PASS=${USER_PASS:-"default!42"}
readonly COMPANY=${COMPANY:-"${DOMAIN%%.*} Inc."}

readonly ADMIN_PASSWORD=${ADMIN_PASSWORD:-8minPass}

create_user () {
    docker run --rm \
        -eDOMAIN=${DOMAIN} \
        --mount source=samba,destination=/samba \
        --mount source=/etc/localtime,destination=/etc/localtime,readonly \
        --mount source=samba-data,destination=/var/lib/samba \        
        p3tr/samba-dc tool user create ${USER_NAME} ${USER_PASS} \
        --use-username-as-cn \
        --mail-address="${USER_MAIL}" \
        --company="\"${COMPANY}\"" \
        --profile-path="\\ADSMember.${DOMAIN}\profiles\peter" \
        --home-drive=H \
        --home-directory="\\ADSMember.${DOMAIN}\peter"
}

list_users () {
#        --mount source=/etc/localtime,destination=/etc/localtime,readonly \
    docker run --rm -it\
        -eDOMAIN=${DOMAIN} \
        --mount source=samba,destination=/samba \
        --mount source=samba-data,destination=/var/lib/samba \
        p3tr/samba-dc tool user list
}

case "$1" in
	create)
		create_user
		;;
    list)
        list_users
        ;;
esac
