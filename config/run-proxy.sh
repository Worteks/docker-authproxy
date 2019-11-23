#!/bin/sh

if test "$DEBUG"; then
    set -x
fi
. /usr/local/bin/nsswrapper.sh

AUTH_METHOD=${AUTH_METHOD:-lemon}
OPENLDAP_BIND_DN_PREFIX=${OPENLDAP_BIND_DN_PREFIX:-'cn=authproxy,ou=services'}
OPENLDAP_BIND_PW=${OPENLDAP_BIND_PW:-'secret'}
OPENLDAP_CONF_DN_PREFIX=${OPENLDAP_CONF_DN_PREFIX:-'ou=lemonldap,ou=config'}
OPENLDAP_DOMAIN=${OPENLDAP_DOMAIN:-'demo.local'}
OPENLDAP_HOST=${OPENLDAP_HOST:-'127.0.0.1'}
OPENLDAP_PROTO=${OPENLDAP_PROTO:-'ldap'}
if test -z "$OPENLDAP_BASE"; then
    OPENLDAP_BASE=`echo "dc=$OPENLDAP_DOMAIN" | sed 's|\.|,dc=|g'`
fi
if test -z "$OPENLDAP_PORT" -a "$OPENLDAP_PROTO" = ldaps; then
    OPENLDAP_PORT=636
elif test -z "$OPENLDAP_PORT"; then
    OPENLDAP_PORT=389
fi
if test -z "$OPENLDAP_SEARCH" -a "$AUTH_METHOD" = ldap; then
    OPENLDAP_SEARCH="ou=users,$OPENLDAP_BASE?uid?sub?(&(objectClass=inetOrgPerson)(!(pwdAccountLockedTime=*)))"
fi
PROXY_BACKEND_BASE=${PROXY_BACKEND_BASE:-/}
PROXY_BACKEND_HOST=${PROXY_BACKEND_HOST:-127.0.0.1}
PROXY_BACKEND_PORT=${PROXY_BACKEND_PORT:-8081}
PROXY_BACKEND_PROTO=${PROXY_BACKEND_PROTO:-http}
PROXY_HTTP_PORT=${PROXY_HTTP_PORT:-8080}
PROXY_PROTO=${PROXY_PROTO:-http}
test -z "$PROXY_SERVER_NAME" && PROXY_SERVER_NAME=`hostname 2>/dev/null || localhost`
export APACHE_DOMAIN=$PROXY_SERVER_NAME
export APACHE_HTTP_PORT=$PROXY_HTTP_PORT
export OPENLDAP_BASE
export OPENLDAP_BIND_DN_PREFIX
export OPENLDAP_DOMAIN
export OPENLDAP_HOST
export PUBLIC_PROTO=$PROXY_PROTO
SSL_INCLUDE=no-ssl
if test -s /var/apache-secret/server.key \
	-a -s /var/apache-secret/server.crt; then
    SSL_INCLUDE=do-ssl
elif test "$PUBLIC_PROTO" = https; then
    SSL_INCLUDE=kindof-ssl
fi

(
    cat <<EOF
<VirtualHost *:$PROXY_HTTP_PORT>
    ServerName $PROXY_SERVER_NAME
    CustomLog /dev/stdout modremoteip
    Include "$SSL_INCLUDE.conf"
    AddDefaultCharset UTF-8
EOF
    if test "$AUTH_METHOD" = lemon; then
	cat <<EOF
    PerlHeaderParserHandler Lemonldap::NG::Handler
EOF
    fi
    if test "$DIRECTORY_INDEX"; then
	cat <<EOF
    DirectoryIndex $DIRECTORY_INDEX
EOF
    fi
    if test -s /rewrite-rules; then
	cat <<EOF
    RewriteEngine On
EOF
	cat /rewrite-rules
    fi
    if test "$PROXY_BACKEND_PROTO" = https; then
	cat <<EOF
    SSLProxyEngine On
EOF
    fi
    if test "$AUTH_METHOD" = lemon; then
	cat <<EOF
    SetEnvIfNoCase X-Forwarded-User "(.*)" REMOTE_USER=\$1
EOF
    fi
    cat <<EOF
    ProxyPass / $PROXY_BACKEND_PROTO://$PROXY_BACKEND_HOST:$PROXY_BACKEND_PORT$PROXY_BACKEND_BASE
    ProxyPassReverse / $PROXY_BACKEND_PROTO://$PROXY_BACKEND_HOST:$PROXY_BACKEND_PORT$PROXY_BACKEND_BASE
    <Proxy "*">
EOF
    REQUIRE="all granted"
    if test "$AUTH_METHOD" = ldap; then
	REQUIRE=valid-user
	cat <<EOF
	AuthType Basic
	AuthBasicProvider ldap
	AuthLDAPBindDN "$OPENLDAP_BIND_DN_PREFIX,$OPENLDAP_BASE
	AuthLDAPBindPassword "$OPENLDAP_BIND_PW"
	AuthLDAPURL "$OPENLDAP_PROTO://$OPENLDAP_HOST:$OPENLDAP_PORT/$OPENLDAP_SEARCH" NONE
	AuthName "LDAP Auth"
EOF
    fi
    cat <<EOF
	Require $REQUIRE
    </Proxy>
</VirtualHost>
EOF
) >/etc/apache2/sites-enabled/002-proxy.conf

if test "$AUTH_METHOD" = ldap; then
    export APACHE_IGNORE_OPENLDAP=yay
    if test "$OPENLDAP_PROTO" = ldaps -a "$LDAP_SKIP_TLS_VERIFY"; then
	echo "LDAPVerifyServerCert Off" \
	    >>/etc/apache2/sites-enabled/002-proxy.conf
	cat <<EOF
URI		$OPENLDAP_PROTO://$OPENLDAP_HOST:$OPENLDAP_PORT
TLS_REQCERT	never
EOF
    elif test "$OPENLDAP_PROTO" = ldaps; then
	cat <<EOF
URI		$OPENLDAP_PROTO://$OPENLDAP_HOST:$OPENLDAP_PORT
TLS_REQCERT	demand
EOF
    fi >/etc/ldap/ldap.conf
fi

unset PROXY_HTTP_PORT PROXY_PROTO PROXY_SERVER_NAME PROXY_BACKEND_PROTO \
    PROXY_BACKEND_BASE PROXY_BACKEND_HOST PROXY_BACKEND_PORT AUTH_METHOD \
    PROXY_BACKEND_BASE REQUIRE OPENLDAP_SEARCH
. /run-apache.sh
