#!/bin/bash

cw_ROOT=${cw_ROOT:-/opt/clusterware}
if [ ! -d "${cw_ROOT}"/opt/genders ]; then
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
mkdir -p "${cw_ROOT}"/opt/pdsh
pushd /tmp/pdsh-*
./configure --prefix="${cw_ROOT}/opt/pdsh" --with-ssh \
  --with-rcmd-rank-list=ssh,rsh,exec \
  --with-genders \
  --with-readline \
  CPPFLAGS="-I${cw_ROOT}/opt/genders/include" \
  LDFLAGS="-L${cw_ROOT}/opt/genders/lib"
make
make install
popd


pushd "${temp_dir}" > /dev/null
mkdir -p "${temp_dir}/data/opt"
cp -R "${cw_ROOT}/opt/pdsh" "${temp_dir}/data/opt"
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
