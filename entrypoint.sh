#!/bin/sh

set -e

setupDC () {

	# Set variables
	DOMAIN=${DOMAIN:-SAMDOM.LOCAL}
	DOMAINPASS=${DOMAINPASS:-youshouldsetapassword}
	JOIN=${JOIN:-false}
	JOINSITE=${JOINSITE:-NONE}
	MULTISITE=${MULTISITE:-false}
	NOCOMPLEXITY=${NOCOMPLEXITY:-false}
	INSECURELDAP=${INSECURELDAP:-false}
	DNSFORWARDER=${DNSFORWARDER:-NONE}
	HOSTIP=${HOSTIP:-NONE}
	
	LDOMAIN=${DOMAIN,,}
	UDOMAIN=${DOMAIN^^}
	URDOMAIN=${UDOMAIN%%.*}
}

case "$1" in
	start)
		setupDC
	else)
		exec $@
esac

exit 0