# SweetAuthProxy

Apache Proxy authenticating users against LLNG or LDAP

Diverts from https://github.com/Worteks/docker-apache

Build with:
```
$ make build
```

Depends on LDAP & LLNG images

Test with:
```
$ make run
```

Start Demo in OpenShift:

```
$ make ocdemo
```

Cleanup OpenShift assets:

```
$ make ocpurge
```

Environment variables and volumes
----------------------------------

The image recognizes the following environment variables that you can set during
initialization by passing `-e VAR=VALUE` to the Docker `run` command.

|    Variable name           |    Description            | Default                                                     | Inherited From |
| :------------------------- | ------------------------- | ----------------------------------------------------------- | -------------- |
|  `APACHE_IGNORE_OPENLDAP`  | Ignore LemonLDAP autoconf | undef                                                       | wsweet/apache  |
|  `AUTH_METHOD`             | Apache Auth Method        | `lemon`, could be `ldap` or `none`                          |                |
|  `OPENLDAP_BASE`           | OpenLDAP Base             | seds `OPENLDAP_DOMAIN`, default produces `dc=demo,dc=local` | wsweet/apache  |
|  `OPENLDAP_BIND_DN_RREFIX` | OpenLDAP Bind DN Prefix   | `cn=whitepages,ou=services`                                 | wsweet/apache  |
|  `OPENLDAP_BIND_PW`        | OpenLDAP Bind Password    | `secret`                                                    | wsweet/apache  |
|  `OPENLDAP_CONF_DN_RREFIX` | OpenLDAP Conf DN Prefix   | `cn=lemonldap,ou=config`                                    | wsweet/apache  |
|  `OPENLDAP_DOMAIN`         | OpenLDAP Domain Name      | `demo.local`                                                | wsweet/apache  |
|  `OPENLDAP_HOST`           | OpenLDAP Backend Address  | `127.0.0.1`                                                 | wsweet/apache  |
|  `OPENLDAP_PORT`           | OpenLDAP Bind Port        | `389` or `636` depending on `OPENLDAP_PROTO`                | wsweet/apache  |
|  `OPENLDAP_PROTO`          | OpenLDAP Proto            | `ldap`                                                      | wsweet/apache  |
|  `OPENLDAP_SEARCH`         | OpenLDAP Search URI       | `ou=users,$OPENLDAP_BASE?uid?sub?(xxx)`                     |                |
|  `PROXY_BACKEND_BASE`      | Proxy Backend Base        | `/`                                                         |                |
|  `PROXY_BACKEND_HOST`      | Proxy Backend Host        | `127.0.0.1`                                                 |                |
|  `PROXY_BACKEND_PORT`      | Proxy Backend Port        | `8081`                                                      |                |
|  `PROXY_BACKEND_PROTO`     | Proxy Backend Proto       | `http`                                                      |                |
|  `PROXY_HTTP_PORT`         | Proxy Frontend Port       | `8080`                                                      |                |
|  `PROXY_PROTO`             | Proxy Frontend Proto      | `http`                                                      |                |
|  `PROXY_SERVER_NAME`       | Proxy ServerName          | server hostname                                             |                |

|  Volume mount point         | Description                                                                     | Inherited From |
| :-------------------------- | ------------------------------------------------------------------------------- | -------------- |
|  `/var/apache-secrets`      | Apache Secrets root - install server.crt, server.key and ca.crt to enable https | wsweet/apache  |
|  `/vhosts`                  | Apache VirtualHosts templates root - processed during container start           | wsweet/apache  |
