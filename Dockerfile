FROM wsweet/apache:latest

# Apache Proxy image for OpenShift Origin

LABEL io.k8s.description="Apache Auth Proxy." \
      io.k8s.display-name="Apache 2.4 LLNG-basd Auth Proxy" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="apache,apache2,apache24" \
      io.openshift.non-scalable="false" \
      help="For more information visit https://github.com/Worteks/docker-authproxy" \
      maintainer="Thibaut DEMARET <thidem@worteks.com>, Samuel MARTIN MORO <sammar@worteks.com>" \
      version="1.0"

USER root
COPY config/* /
RUN if test "$DO_UPGRADE"; then \
	echo "# Install Proxy Dependencies" \
	&& apt-get -y update \
	&& apt-get -y upgrade \
	&& apt-get -y dist-upgrade \
	&& apt-get clean; \
    fi \
    && a2enmod proxy proxy_http proxy_wstunnel proxy_balancer ldap authnz_ldap \
    && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
	/etc/ldap/ldap.conf \
    && for dir in /etc/lemonldap-ng /etc/ldap; \
	do \
	    mkdir -p $dir 2>/dev/null \
	    && chown -R 1001:root $dir \
	    && chmod -R g=u $dir; \
	done \
    && unset HTTP_PROXY HTTPS_PROXY NO_PROXY DO_UPGRADE http_proxy https_proxy

USER 1001
ENTRYPOINT ["dumb-init","--","/run-proxy.sh"]
CMD "/usr/sbin/apache2ctl" "-D" "FOREGROUND"
