#!/bin/bash

set -e

FL_ROOT=${FL_ROOT:-/opt/flight-direct}
if [ ! -d "${FL_ROOT}"/opt/genders ]; then
    echo "Genders must be installed to compile this package."
    exit 1
fi

package_name='pdsh'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

sudo yum install -y readline-devel

temp_dir=$(mktemp -d /tmp/forge-${package_name}-build-XXXXX)

cp -r * "${temp_dir}"
mkdir -p "${temp_dir}/data"

cp ../pdsh-module.template ../motd.sh "${temp_dir}/data"

curl -L "https://github.com/chaos/pdsh/releases/download/pdsh-2.33/pdsh-2.33.tar.gz" -o /tmp/pdsh-source.tar.gz
tar -C /tmp -xf "/tmp/pdsh-source.tar.gz"
mkdir -p "${FL_ROOT}"/opt/pdsh
pushd /tmp/pdsh-*
./configure --prefix="${FL_ROOT}/opt/pdsh" --with-ssh \
  --with-rcmd-rank-list=ssh,rsh,exec \
  --with-genders \
  --with-readline \
  CPPFLAGS="-I${FL_ROOT}/opt/genders/include" \
  LDFLAGS="-L${FL_ROOT}/opt/genders/lib"
make
make install
popd


pushd "${temp_dir}" > /dev/null
mkdir -p "${temp_dir}/data/opt"
cp -R "${FL_ROOT}/opt/pdsh" "${temp_dir}/data/opt"
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
