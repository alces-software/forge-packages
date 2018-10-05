#!/bin/bash

set -e

FL_ROOT=${FL_ROOT:-/opt/flight-direct}
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

# Set the version number so the build file names are known in advance
major_version='1'
minor_version='22'
patch_version='1'
tag="${major_version}-${minor_version}-${patch_version}"
version="${major_version}.${minor_version}"

curl -L "https://github.com/chaos/genders/releases/download/genders-$tag/genders-${version}.tar.gz" -o /tmp/genders-source.tar.gz
tar -C /tmp -xzf "/tmp/genders-source.tar.gz"
mkdir -p "${FL_ROOT}"/opt/genders
pushd /tmp/genders-*
./configure --prefix="${FL_ROOT}/opt/genders" \
  --with-genders-file="${FL_ROOT}/etc/genders" \
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
cp -R "${FL_ROOT}/opt/genders" "${temp_dir}/data/opt"
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
