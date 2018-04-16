#!/bin/bash

yum install -y -e0 pcre openssl

cp -R data/* "${cw_ROOT}"

mkdir -p "${cw_ROOT}"/etc/clusterware-www/{http.d,server-http.d,server-https.d}
cat <<EOF > "${cw_ROOT}"/etc/clusterware-www.rc
################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2016 Stephen F. Norledge and Alces Software Ltd.
##
################################################################################
#cw_WWW_http_enabled=true
#cw_WWW_http_port=80
#cw_WWW_http_redirect_enabled=true
#cw_WWW_https_enabled=true
#cw_WWW_https_port=443
#cw_WWW_ssl_strategy=selfsigned
#cw_WWW_ssl_name=
EOF

mkdir -p /var/log/clusterware-www
chmod 750 /var/log/clusterware-www
cp etc/logrotate.d/* "${cw_ROOT}"/etc/logrotate.d

install -Dm644 nginx.conf.tpl "${cw_ROOT}"/opt/clusterware-www/etc/nginx.conf
sed -e "s,_ROOT_,${cw_ROOT},g" -i "${cw_ROOT}"/opt/clusterware-www/etc/nginx.conf

sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
    init/systemd/clusterware-www.service \
    > /etc/systemd/system/clusterware-www.service
