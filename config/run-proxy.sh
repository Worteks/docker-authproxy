#!/bin/sh

if test "$DEBUG"; then
    set -x
fi
. /usr/local/bin/nsswrapper.sh

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
    if test -z "$DO_NOT_AUTH"; then
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
    cat <<EOF
    SetEnvIfNoCase X-Forwarded-User "(.*)" REMOTE_USER=\$1
    ProxyPass / $PROXY_BACKEND_PROTO://$PROXY_BACKEND_HOST:$PROXY_BACKEND_PORT$PROXY_BACKEND_BASE
    ProxyPassReverse / $PROXY_BACKEND_PROTO://$PROXY_BACKEND_HOST:$PROXY_BACKEND_PORT$PROXY_BACKEND_BASE
    <Proxy "*">
        <IfVersion >= 2.3>
            Require all granted
        </IfVersion>
        <IfVersion < 2.3>
            Order Deny,Allow
            Allow from all
        </IfVersion>
    </Proxy>
</VirtualHost>
EOF
) >/etc/apache2/sites-enabled/002-proxy.conf

unset PROXY_HTTP_PORT PROXY_PROTO PROXY_SERVER_NAME PROXY_BACKEND_PROTO \
    PROXY_BACKEND_BASE PROXY_BACKEND_HOST PROXY_BACKEND_PORT PROXY_BACKEND_BASE
. /run-apache.sh
