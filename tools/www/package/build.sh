#!/bin/bash

cw_ROOT=${cw_ROOT:-/opt/clusterware}
package_name='www'

yum install -y -e0 pcre-devel openssl-devel

temp_dir=$(mktemp -d /tmp/forge-${package_name}-build-XXXXX)

cp -r * "${temp_dir}"
mkdir -p "${temp_dir}/data"

curl "http://nginx.org/download/nginx-1.10.1.tar.gz" -o /tmp/nginx.tar.gz
tar -C /tmp -xzf /tmp/nginx.tar.gz
pushd /tmp/nginx-1.10.1
DESTDIR="${cw_ROOT}/opt/clusterware-www"
./configure \
  --prefix=$DESTDIR/etc/nginx \
  --conf-path=$DESTDIR/etc/nginx.conf \
  --sbin-path=$DESTDIR/bin/nginx \
  --pid-path=/var/run/clusterware-www.pid \
  --lock-path=/var/run/lock/clusterware-www.lock \
  --user=nobody \
  --group=nobody \
  --http-log-path=/var/log/clusterware-www/access.log \
  --error-log-path=stderr \
  --http-client-body-temp-path=$DESTDIR/var/lib/client-body \
  --http-proxy-temp-path=$DESTDIR/var/lib/proxy \
  --http-fastcgi-temp-path=$DESTDIR/var/lib/fastcgi \
  --http-scgi-temp-path=$DESTDIR/var/lib/scgi \
  --http-uwsgi-temp-path=$DESTDIR/var/lib/uwsgi \
  --with-imap \
  --with-imap_ssl_module \
  --with-ipv6 \
  --with-pcre-jit \
  --with-file-aio \
  --with-http_dav_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_realip_module \
  --with-http_v2_module \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_addition_module \
  --with-http_degradation_module \
  --with-http_flv_module \
  --with-http_mp4_module \
  --with-http_secure_link_module \
  --with-http_sub_module
make
make install

rm "$DESTDIR"/etc/*.default
install -dm700 "$DESTDIR"/etc/conf.d
install -d "$DESTDIR"/man/man8/
gzip -9c man/nginx.8 > "$DESTDIR"/man/man8/nginx.8.gz
install -d "$DESTDIR"/var/lib
install -dm700 "$DESTDIR"/var/lib/proxy

popd

pushd "${temp_dir}" > /dev/null
mkdir -p "${temp_dir}/data/opt"
cp -R "${cw_ROOT}/opt/clusterware-www" "${temp_dir}/data/opt"
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
