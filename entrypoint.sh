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
#	readonly HOST_NAME=${HOST_NAME:-DC_$RANDOM}
	
	readonly LC_DOMAIN=$(toLower ${DOMAIN})
	readonly UC_DOMAIN=$(toUpper ${DOMAIN})
	readonly SUBDOMAIN=${UC_DOMAIN%%.*}

	OTHER_OPTIONS=""
	if [[ "${HOST_IP}" != "NONE" ]]; then
		OTHER_OPTIONS="--host-ip=$HOST_IP"
	fi
	# Note that the samba-tool automatically adds an exisiting DNS if there is one.
	if [[ "${DNS_FORWARDER}" != "NONE" ]]; then
		OTHER_OPTIONS="${OTHER_OPTIONS} --option='dns forwarder'=${DNS_FORWARDER}"
	fi
	if [[ ${INSECURE_LDAP} == "true" ]]; then
		OTHER_OPTIONS="${OTHER_OPTIONS} --option='ldap server require strong auth'=no"
	fi
	readonly OTHER_OPTIONS

	# Only initialize smb.conf if it is not yet there
	if [[ ! -e /samba/etc/smb.conf ]]; then

		samba-tool domain provision \
			--server-role=dc \
			--dns-backend=SAMBA_INTERNAL \
			--use-rfc2307 \
			--realm=${UC_DOMAIN} \
			--domain=${SUBDOMAIN} \
			--adminpass=${ADMIN_PASSWORD} \
			--targetdir=/samba \
			--option='wins support'=yes \
			--option="idmap config ${UC_DOMAIN}: range"='10000-20000' \
			--option="idmap config ${UC_DOMAIN}: backend"=ad \
			${OTHER_OPTIONS}
#			--option='winbind nss info'=rfc2307 \
#			--option='netbios name'=DC_${SUBDOMAIN} \
		
		test -e /etc/samba || mkdir /etc/samba
		ln -sf /samba/etc/smb.conf /etc/samba/smb.conf
		cp -f /samba/private/krb5.conf /etc/krb5.conf

		if [[ ${NO_COMPLEXITY} == "true" ]]; then
			samba-tool domain passwordsettings set --complexity=off
			samba-tool domain passwordsettings set --history-length=0
			samba-tool domain passwordsettings set --min-pwd-age=0
			samba-tool domain passwordsettings set --max-pwd-age=0
		fi
	fi
}

# untested....
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

adjustResolfConf () {
	readonly IPADDRESS=$(ip route show default | cut -d ' ' -f8 | tail -1)
	readonly SEARCHREALM=$(echo "\n" | samba-tool testparm --configfile /samba/etc/smb.conf 2>/dev/null | grep realm|cut -d ' ' -f3|tail -1)
	
	# Note: 
	# The first 'nameserver' should be the secondary DC the second 'nameserver' the the primary himself
	# (for the secondary inverse). FIXME: Support secondary DC

    cat > /etc/resolv.conf << EOF
search=$(toLower ${SEARCHREALM})
nameserver=${IPADDRESS}
EOF
	echo "[INFO] Adjusted resolv.conf:"
	cat /etc/resolv.conf
}

startPrimaryDC () {
	test -e /etc/samba || mkdir /etc/samba
	test -e /etc/samba/smb.conf && rm /etc/samba/smb.conf
	ln -s /samba/etc/smb.conf /etc/samba/smb.conf
	cp -f /samba/private/krb5.conf /etc/krb5.conf

	cat << 'EOF'
       _____                          _            ___   ___         
  _ __|__ / |_   ___   ___ __ _ _ __ | |__  __ _  |   \ / __|        
 | '_ \|_ \  _| |___| (_-</ _` | '  \| '_ \/ _` | | |) | (__         
 | .__/___/\__|       /__/\__,_|_|_|_|_.__/\__,_| |___/ \___|        
 |_|                                                                 
---------------------------------------------------------------------
    53   - DNS
    88   - Kerberos
    135  - End Point Mapper (DCE/RPC Locator Service)
    139  - NetBIOS Session
    389  - LDAP
    445  - SMB over TCP / CIFS
    464  - Kerberos Password
    636  - LDAPS (only if "tls enabled = yes")
    1024-5000 dynamic RPC-ports
    3268 - global catalogue
    3269 - global catalogue SSL
---------------------------------------------------------------------
EOF
	adjustResolfConf
	echo "\n" | samba-tool testparm --configfile /samba/etc/smb.conf

	exec samba --interactive --configfile=/samba/etc/smb.conf
}

case "$1" in
	setup)
		setupDC
		;;
	start)
		startPrimaryDC
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