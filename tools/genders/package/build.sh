#!/bin/bash

cw_ROOT=${cw_ROOT:-/opt/clusterware}
package_name='genders'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

sudo yum install -y flex bison

temp_dir=$(mktemp -d /tmp/forge-${package_name}-build-XXXXX)

cp -r * "${temp_dir}"
mkdir -p "${temp_dir}/data"

cp -pr ../etc "${temp_dir}/data"

curl -L "https://github.com/chaos/genders/releases/download/genders-1-22-1/genders-1.22.tar.gz" -o /tmp/genders-source.tar.gz
tar -C /tmp -xzf "/tmp/genders-source.tar.gz"
mkdir -p "${cw_ROOT}"/opt/genders
pushd /tmp/genders-*
./configure --prefix="${cw_ROOT}/opt/genders" \
  --with-genders-file="/opt/clusterware/etc/genders" \
  --without-java-extensions \
  --without-perl-extensions \
  --without-python-extensions
popd

patch -d /tmp/genders-* -p0 < ../genders-file-envvar.patch

pushd /tmp/genders-*
make
make install
popd

pushd "${temp_dir}" > /dev/null
mkdir -p "${temp_dir}/data/opt"
cp -R "${cw_ROOT}/opt/genders" "${temp_dir}/data/opt"
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
