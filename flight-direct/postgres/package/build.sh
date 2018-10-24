#!/bin/bash

set -e

package_name='postgres'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

yum install -e0 -y wget

temp_dir=$(mktemp -d /tmp/${package_name}-build-XXXXX)
compile_dir=$(mktemp -d /tmp/${package_name}-compile-XXXXX)
prefix=$temp_dir/fl_root/opt/postgres

cp -r * "${temp_dir}"

pushd $compile_dir > /dev/null
# Fetches the postgres source code
postgres='postgresql-9.6.9'
wget https://ftp.postgresql.org/pub/source/v9.6.9/$postgres.tar.gz
tar -xzf $postgres.tar.gz
cd $postgres

# Configures and installs postgres
./configure --prefix=$prefix
make world -j $(nproc)
make install-world -j $(nproc)
popd > /dev/null

pushd $temp_dir > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null


mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
