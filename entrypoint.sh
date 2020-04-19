#!/bin/sh

set -e

toLower () {
	echo ${@}|tr '[:upper:]' '[:lower:]'
}

toUpper () {
	echo ${@}|tr '[:lower:]' '[:upper:]'
}

setupDC () {

	# Set variables
	readonly DOMAIN=${DOMAIN:-SAMDOM.LOCAL}
	readonly ADMIN_PASSWORD=${ADMIN_PASSWORD:-youshouldsetapassword}
	readonly NO_COMPLEXITY=$(toLower ${NO_COMPLEXITY:-false})
	readonly INSECURE_LDAP=$(toLower ${INSECURE_LDAP:-false})
	readonly DNS_FORWARDER=${DNS_FORWARDER:-NONE}
	readonly HOST_IP=${HOST_IP:-NONE}
	
	readonly LC_DOMAIN=$(toLower ${DOMAIN})
	readonly UC_DOMAIN=$(toUpper ${DOMAIN})
	readonly SUBDOMAIN=${UC_DOMAIN%%.*}

	OTHER_OPTIONS=""
	if [[ "$HOST_IP" != "NONE" ]]; then
		OTHER_OPTIONS="--host-ip=$HOST_IP"
	fi
	# Note that the samba-tool automatically adds an exisiting DNS if there is one.
	if [[ $DNS_FORWARDER != "NONE" ]]; then
		OTHER_OPTIONS="${OTHER_OPTIONS} --option='dns forwarder'=${DNS_FORWARDER}"
	fi
	if [[ ${INSECURE_LDAP} == "true" ]]; then
		OTHER_OPTIONS="${OTHER_OPTIONS} --option='ldap server require strong auth'=no"
	fi
	readonly OTHER_OPTIONS

	# Only initialize smb.conf if it is not yet there
	if [[ ! -e /samba/etc/smb.conf ]]; then

		samba-tool domain provision \
			--targetdir=/samba \
			--use-rfc2307 \
			--domain=${SUBDOMAIN} \
			--realm=${UC_DOMAIN} \
			--server-role=dc \
			--dns-backend=SAMBA_INTERNAL \
			--adminpass=${ADMIN_PASSWORD} \
			--option='netbios name'=DC_${SUBDOMAIN} \
			--option='wins support'=yes \
			--option='winbind nss info'=rfc2307 \
			--option="idmap config ${UC_DOMAIN}: range"='10000-20000' \
			--option="idmap config ${UC_DOMAIN}: backend"=ad \
			${OTHER_OPTIONS}
		
		test -e /etc/samba || mkdir /etc/samba
		ln -s /samba/etc/smb.conf /etc/samba/smb.conf
		cp -f /samba/private/krb5.conf /etc/krb5.conf

		if [[ ${NO_COMPLEXITY} == "true" ]]; then
			samba-tool domain passwordsettings set --complexity=off
			samba-tool domain passwordsettings set --history-length=0
			samba-tool domain passwordsettings set --min-pwd-age=0
			samba-tool domain passwordsettings set --max-pwd-age=0
		fi
	fi
}

joinDomain () {
	readonly DOMAIN=${DOMAIN:-SAMDOM.LOCAL}
	readonly ADMIN_PASSWORD=${ADMIN_PASSWORD:-youshouldsetapassword}
	readonly JOINSITE=${JOINSITE:-NONE}
	
	readonly LC_DOMAIN=$(toLower ${DOMAIN})
	readonly SUBDOMAIN=${UC_DOMAIN%%.*}

	if [[ ${JOINSITE} == "NONE" ]]; then
		samba-tool domain join ${LC_DOMAIN} DC -U"${SUBDOMAIN}\administrator" --password="${ADMIN_PASSWORD}" --dns-backend=SAMBA_INTERNAL
	else
		samba-tool domain join ${LC_DOMAIN} DC -U"${SUBDOMAIN}\administrator" --password="${ADMIN_PASSWORD}" --dns-backend=SAMBA_INTERNAL --site=${JOINSITE}
	fi
}

startDC () {
	exec samba --interactive --configfile=/samba/etc/smb.conf
}

case "$1" in
	setup)
		setupDC
		;;
	start)
		startDC
		;;
	join)
		joinDomain
		;;
	tool)
		runSambaTool
		;;
	*)
		exec $@
		;;
esac

exit 0